// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { IRouter } from "./interfaces/IRouter.sol";
import { HelperLib } from "./libraries/HelperLib.sol";

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { Ownable2Step } from "./external/Ownable2Step.sol";

import { IMultiswapRouter } from "./interfaces/IMultiswapRouter.sol";

contract MultiswapRouter is UUPSUpgradeable, Initializable, Ownable2Step, IMultiswapRouter {
    // =========================
    // storage
    // =========================

    /// @dev mask for UniswapV3 pair designation
    /// if `mask & pair == true`, the swap is performed using the UniswapV3 logic
    bytes32 private constant UNISWAP_V3_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    /// address mask: `mask & pair == address(pair)`
    address private constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    /// fee mask: `mask & (pair >> 160) == fee in pair`
    uint24 private constant FEE_MASK = 0xffffff;

    /// @dev minimum and maximum possible values of SQRT_RATIO in UniswapV3
    uint160 private constant MIN_SQRT_RATIO_PLUS_ONE = 4_295_128_740;
    uint160 private constant MAX_SQRT_RATIO_MINUS_ONE =
        1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

    /// @dev 2**255 - 1
    uint256 private constant CAST_INT_CONSTANT =
        57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_967;

    /// @dev cache for swapV3Callback
    address private _poolAddressCache;

    /// @dev fee logic
    uint256 private constant FEE_MAX = 10_000;
    uint256 private _protocolFee;

    /// @dev protocolPart of referralFee: _referralFee & PROTOCOL_PART_MASK
    /// referralPart of referralFee: _referralFee >> 128
    uint256 private constant PROTOCOL_PART_MASK = 0xffffffffffffffffffffffffffffffff;
    uint256 private _referralFee;

    mapping(address owner => mapping(address token => uint256 balance)) private _profit;

    // =========================
    // constructor
    // =========================

    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 protocolFee,
        ReferralFee calldata newReferralFee,
        address newOwner
    )
        external
        initializer
    {
        _setProtocolFee(protocolFee);
        _setReferralFee(newReferralFee, protocolFee);

        _transferOwnership(newOwner);
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc IMultiswapRouter
    function getVersion() external view returns (uint8) {
        return _getInitializedVersion();
    }

    /// @inheritdoc IMultiswapRouter
    function profit(address owner, address token) external view returns (uint256 balance) {
        return _profit[owner][token];
    }

    /// @inheritdoc IMultiswapRouter
    function fees() external view returns (uint256 protocolFee, ReferralFee memory referralFee) {
        assembly ("memory-safe") {
            protocolFee := sload(_protocolFee.slot)

            let referralFee_ := sload(_referralFee.slot)
            mstore(referralFee, and(PROTOCOL_PART_MASK, referralFee_))
            mstore(add(referralFee, 32), shr(128, referralFee_))
        }
    }

    // =========================
    // admin logic
    // =========================

    /// @inheritdoc IMultiswapRouter
    function changeProtocolFee(uint256 newProtocolFee) external onlyOwner {
        _setProtocolFee(newProtocolFee);
    }

    /// @inheritdoc IMultiswapRouter
    function changeReferralFee(ReferralFee calldata newReferralFee) external onlyOwner {
        _setReferralFee(newReferralFee, _protocolFee);
    }

    // =========================
    // fees logic
    // =========================

    /// @inheritdoc IMultiswapRouter
    function collectProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        uint256 balanceOf = _profit[address(this)][token];
        if (balanceOf >= amount) {
            unchecked {
                _profit[address(this)][token] -= amount;
            }
            TransferHelper.safeTransfer(token, recipient, amount);
        }
    }

    /// @inheritdoc IMultiswapRouter
    function collectReferralFees(address token, address recipient, uint256 amount) external {
        uint256 balanceOf = _profit[msg.sender][token];
        if (balanceOf >= amount) {
            unchecked {
                _profit[msg.sender][token] -= amount;
            }
            TransferHelper.safeTransfer(token, recipient, amount);
        }
    }

    /// @inheritdoc IMultiswapRouter
    function collectProtocolFees(address token, address recipient) external onlyOwner {
        uint256 balanceOf = _profit[address(this)][token];
        if (balanceOf > 0) {
            unchecked {
                _profit[address(this)][token] -= balanceOf;
            }
            TransferHelper.safeTransfer(token, recipient, balanceOf);
        }
    }

    /// @inheritdoc IMultiswapRouter
    function collectReferralFees(address token, address recipient) external {
        uint256 balanceOf = _profit[msg.sender][token];
        if (balanceOf > 0) {
            unchecked {
                _profit[msg.sender][token] -= balanceOf;
            }
            TransferHelper.safeTransfer(token, recipient, balanceOf);
        }
    }

    // =========================
    // main logic
    // =========================

    //// @inheritdoc IMultiswapRouter
    function multiswap(MultiswapCalldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert MultiswapRouter_InvalidArray();
        }

        uint256 lastIndex;
        unchecked {
            lastIndex = length - 1;
        }

        bytes32 pair = data.pairs[0];
        address firstPair;
        bool uni3;

        assembly ("memory-safe") {
            // take the first pair in the array
            firstPair := and(pair, ADDRESS_MASK)
            // find out which version of the protocol it belongs to
            uni3 := and(pair, UNISWAP_V3_MASK)
        }

        uint256 amountIn = data.amountIn;
        address tokenIn = data.tokenIn;

        // execute transferFrom:
        //     if the pair belongs to version 2 of the protocol -> transfer tokens to the pair
        //     if version 3 - to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, uni3 ? address(this) : firstPair, amountIn);

        bytes32 addressThisBytes32 = _addressThisBytes32();

        uint256 balanceOutBeforeLastSwap;
        bool uni3Next;
        bytes32 destination;
        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            if (i == lastIndex) {
                // if the pair is the last in the array - the next token recipient after the swap is address(this)
                destination = addressThisBytes32;
            } else {
                // otherwise take the next pair
                destination = data.pairs[_unsafeAddOne(i)];
            }

            assembly ("memory-safe") {
                // if the next pair belongs to version 3 of the protocol - the address
                // of the router is set as the recipient, otherwise - the next pair
                uni3Next := and(destination, UNISWAP_V3_MASK)
            }

            if (uni3) {
                (amountIn, tokenIn, balanceOutBeforeLastSwap) =
                    _swapUniV3(i == lastIndex, pair, amountIn, tokenIn, uni3Next ? addressThisBytes32 : destination);
            } else {
                (amountIn, tokenIn, balanceOutBeforeLastSwap) =
                    _swapUniV2(i == lastIndex, pair, tokenIn, uni3Next ? addressThisBytes32 : destination);
            }
            // upgrade the pair for the next swap
            pair = destination;
            uni3 = uni3Next;
        }

        uint256 balanceOutAfterLastSwap = IERC20(tokenIn).balanceOf(address(this));

        if (balanceOutAfterLastSwap < balanceOutBeforeLastSwap) {
            revert MultiswapRouter_InvalidOutAmount();
        }

        uint256 exactAmountOut;
        unchecked {
            exactAmountOut = balanceOutAfterLastSwap - balanceOutBeforeLastSwap;
        }

        if (exactAmountOut < data.minAmountOut) {
            revert MultiswapRouter_InvalidOutAmount();
        }

        exactAmountOut = _writeFees(exactAmountOut, data.referralAddress, tokenIn);

        TransferHelper.safeTransfer(tokenIn, msg.sender, exactAmountOut);
    }

    /// @inheritdoc IMultiswapRouter
    function partswap(PartswapCalldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert MultiswapRouter_InvalidArray();
        }
        if (length != data.amountsIn.length) {
            revert MultiswapRouter_InvalidPartswapCalldata();
        }

        address tokenIn;
        address tokenOut;
        {
            uint256 fullAmountCheck;
            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                unchecked {
                    fullAmountCheck += data.amountsIn[i];
                }
            }

            uint256 fullAmount = data.fullAmount;
            // sum of amounts array must be lte to fullAmount
            if (fullAmountCheck > fullAmount) {
                revert MultiswapRouter_InvalidPartswapCalldata();
            }

            tokenIn = data.tokenIn;
            tokenOut = data.tokenOut;

            // Transfer full amount in for all swaps
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), fullAmount);
        }

        bytes32 addressThisBytes32 = _addressThisBytes32();

        bytes32 pair;
        bool uni3;
        uint256 amountBefore = IERC20(tokenOut).balanceOf(address(this));

        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            pair = data.pairs[i];
            assembly ("memory-safe") {
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (uni3) {
                _swapUniV3(false, pair, data.amountsIn[i], tokenIn, addressThisBytes32);
            } else {
                address _pair;
                assembly ("memory-safe") {
                    _pair := and(pair, ADDRESS_MASK)
                }
                TransferHelper.safeTransfer(tokenIn, _pair, data.amountsIn[i]);
                _swapUniV2(false, pair, tokenIn, addressThisBytes32);
            }
        }

        uint256 amountAfter = IERC20(tokenOut).balanceOf(address(this));

        if (amountAfter < amountBefore) {
            revert MultiswapRouter_InvalidOutAmount();
        }

        uint256 exactAmountOut;
        unchecked {
            exactAmountOut = amountAfter - amountBefore;
        }

        if (exactAmountOut < data.minAmountOut) {
            revert MultiswapRouter_InvalidOutAmount();
        }

        exactAmountOut = _writeFees(exactAmountOut, data.referralAddress, tokenOut);

        TransferHelper.safeTransfer(tokenOut, msg.sender, exactAmountOut);
    }

    // for V3Callback
    fallback() external {
        // Checking that msg.sender is equal to the value from the cache
        // and zeroing the storage
        if (msg.sender != _poolAddressCache) {
            revert MultiswapRouter_SenderMustBeUniswapV3Pool();
        }
        _poolAddressCache = address(0);

        int256 amount0Delta;
        int256 amount1Delta;
        address tokenIn;

        assembly ("memory-safe") {
            amount0Delta := calldataload(4)
            amount1Delta := calldataload(36)
            tokenIn := calldataload(132)
        }

        // swaps entirely within 0-liquidity regions are not supported
        if (amount0Delta == 0 && amount1Delta == 0) {
            revert MultiswapRouter_FailedV3Swap();
        }

        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        // transfer tokens to the pool address
        TransferHelper.safeTransfer(tokenIn, msg.sender, amountToPay);
    }

    // =========================
    // internal methods
    // =========================

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function _setProtocolFee(uint256 protocolFee) internal {
        if (protocolFee > FEE_MAX) {
            revert MultiswapRouter_InvalidFeeValue();
        }
        _protocolFee = protocolFee;
    }

    function _setReferralFee(ReferralFee calldata newReferralFee, uint256 protocolFee) internal {
        unchecked {
            uint256 protocolPart = newReferralFee.protocolPart;
            uint256 referralPart = newReferralFee.referralPart;

            if ((referralPart + protocolPart) > protocolFee) {
                revert MultiswapRouter_InvalidFeeValue();
            }

            assembly ("memory-safe") {
                sstore(_referralFee.slot, or(shl(128, referralPart), protocolPart))
            }
        }
    }

    function _writeFees(uint256 exactAmount, address referralAddress, address token) internal returns (uint256) {
        if (referralAddress == address(0)) {
            unchecked {
                uint256 fee = (exactAmount * _protocolFee) / FEE_MAX;
                _profit[address(this)][token] += fee;

                return exactAmount - fee;
            }
        } else {
            uint256 protocolPart;
            uint256 referralPart;
            assembly ("memory-safe") {
                let referralFee_ := sload(_referralFee.slot)
                protocolPart := and(PROTOCOL_PART_MASK, referralFee_)
                referralPart := shr(128, referralFee_)
            }

            unchecked {
                uint256 referralFeePart = (exactAmount * referralPart) / FEE_MAX;
                uint256 protocolFeePart = (exactAmount * protocolPart) / FEE_MAX;
                _profit[referralAddress][token] += referralFeePart;
                _profit[address(this)][token] += protocolFeePart;

                return exactAmount - referralFeePart - protocolFeePart;
            }
        }
    }

    /// @dev uniswapV3 swap exact tokens
    function _swapUniV3(
        bool lastSwap,
        bytes32 _pool,
        uint256 amountIn,
        address tokenIn,
        bytes32 _destination
    )
        internal
        returns (uint256 amountOut, address tokenOut, uint256 balanceOutBeforeLastSwap)
    {
        IRouter pool;
        address destination;
        assembly ("memory-safe") {
            pool := and(_pool, ADDRESS_MASK)
            destination := and(_destination, ADDRESS_MASK)
        }

        // if token0 in the pool is tokenIn - tokenOut == token1, otherwise tokenOut == token0
        tokenOut = pool.token0();
        if (tokenOut == tokenIn) {
            tokenOut = pool.token1();
        }

        if (lastSwap) {
            balanceOutBeforeLastSwap = IERC20(tokenOut).balanceOf(address(this));
        }

        bool zeroForOne = tokenIn < tokenOut;

        // cast a uint256 to a int256, revert on overflow
        // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol#L24
        if (amountIn > CAST_INT_CONSTANT) {
            revert MultiswapRouter_InvalidIntCast();
        }

        // caching pool address in storage
        _poolAddressCache = address(pool);
        (int256 amount0, int256 amount1) = pool.swap(
            destination,
            zeroForOne,
            int256(amountIn),
            (zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            abi.encode(tokenIn)
        );

        // return the number of tokens received as a result of the swap
        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @dev uniswapV2 swap exact tokens
    function _swapUniV2(
        bool lastSwap,
        bytes32 _pair,
        address tokenIn,
        bytes32 _destination
    )
        internal
        returns (uint256 amountOutput, address tokenOut, uint256 balanceOutBeforeLastSwap)
    {
        IRouter pair;
        uint256 fee;
        address destination;
        assembly ("memory-safe") {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(FEE_MASK, shr(160, _pair))
            destination := and(_destination, ADDRESS_MASK)
        }

        // if token0 in the pool is tokenIn - tokenOut == token1, otherwise tokenOut == token0
        address token0 = pair.token0();
        tokenOut = tokenIn == token0 ? pair.token1() : token0;

        if (lastSwap) {
            balanceOutBeforeLastSwap = IERC20(tokenOut).balanceOf(address(this));
        }

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) =
                tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = IERC20(tokenIn).balanceOf(address(pair)) - reserveInput;
            }

            // get the output number of tokens after swap
            amountOutput = HelperLib.getAmountOut(amountInput, reserveInput, reserveOutput, fee);
        }

        (uint256 amount0Out, uint256 amount1Out) =
            tokenIn == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));

        if (
            // first do the swap via the most common swap function selector
            // swap(uint256,uint256,address,bytes) selector
            !_makeCall(address(pair), abi.encodeWithSelector(0x022c0d9f, amount0Out, amount1Out, destination, bytes("")))
        ) {
            if (
                // if revert - try to swap through another selector
                // swap(uint256,uint256,address) selector
                !_makeCall(address(pair), abi.encodeWithSelector(0x6d9a640a, amount0Out, amount1Out, destination))
            ) {
                revert MultiswapRouter_FailedV2Swap();
            }
        }
    }

    /// @dev check for overflow has been removed for optimization
    function _unsafeAddOne(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _addressThisBytes32() internal view returns (bytes32 addressThisBytes32) {
        assembly ("memory-safe") {
            addressThisBytes32 := address()
        }
    }

    /// @dev low-level call, returns true if successful
    function _makeCall(address addr, bytes memory data) internal returns (bool success) {
        (success,) = addr.call(data);
    }
}
