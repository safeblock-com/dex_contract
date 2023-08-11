// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {HelperLib} from "./libraries/HelperLib.sol";

contract MultiswapRouter {
    // =========================
    // Storage
    // =========================

    // mask for UniswapV3 pair designation
    // if `mask & pair == true`, the swap is performed using the UniswapV3 logic
    bytes32 private constant UNISWAP_V3_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    // address mask: `mask & pair == address(pair)`
    address private constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    // fee mask: `mask & (pair >> 160) == fee in pair`
    uint24 private constant FEE_MASK = 0xffffff;

    // minimum and maximum possible values of SQRT_RATIO in UniswapV3
    uint160 private constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
    uint160 private constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    // 2**255
    uint256 private constant CAST_INT_CONSTANT =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // address(this) in bytes32 representation
    bytes32 private immutable ADDRESS_THIS_BYTES32;

    // cache for swapV3Callback
    address private _poolAddressCache;

    // ownership control
    address private _owner;

    // fee logic
    uint256 private constant FEE_MAX = 10000;
    uint256 private _protocolFee;

    struct RefferalFee {
        uint256 protocolPart;
        uint256 refferalPart;
    }
    RefferalFee private _refferalFee;
    mapping(address owner => mapping(address token => uint256 balance)) public profit;

    // =========================
    // Constructor
    // =========================

    constructor(uint256 protocolFee_, RefferalFee memory refferalFee_) {
        if (
            protocolFee_ > FEE_MAX ||
            refferalFee_.refferalPart + refferalFee_.protocolPart > protocolFee_
        ) {
            revert MultiswapRouter_InvalidFeeValue();
        }
        _protocolFee = protocolFee_;
        _refferalFee = refferalFee_;

        bytes32 addressThisBytes32;
        assembly {
            addressThisBytes32 := address()
        }
        ADDRESS_THIS_BYTES32 = addressThisBytes32;

        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // =========================
    // Modifiers
    // =========================

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert MultiswapRouter_SenderIsNotOwner();
        }

        _;
    }

    // =========================
    // Events
    // =========================

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // =========================
    // Errors
    // =========================

    error MultiswapRouter_InvalidFeeValue();
    error MultiswapRouter_SenderIsNotOwner();
    error MultiswapRouter_InvalidOutAmount();

    error MultiswapRouter_FailedV2Swap();

    error MultiswapRouter_InvalidPairsArray();
    error MultiswapRouter_FailedV3Swap();
    error MultiswapRouter_SenderMustBeUniswapV3Pool();
    error MultiswapRouter_InvalidIntCast();
    error MultiswapRouter_NewOwnerIsZeroAddress();

    // =========================
    // Ownership logic
    // =========================

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert MultiswapRouter_NewOwnerIsZeroAddress();
        }
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // =========================
    // Fees logic
    // =========================

    function fees() external view returns (uint256, RefferalFee memory) {
        return (_protocolFee, _refferalFee);
    }

    function changeProtocolFee(uint256 newProtocolFee) external onlyOwner {
        if (newProtocolFee > FEE_MAX) {
            revert MultiswapRouter_InvalidFeeValue();
        }

        _protocolFee = newProtocolFee;
    }

    function changeRefferalFee(RefferalFee memory newRefferalFee) external onlyOwner {
        if ((newRefferalFee.refferalPart + newRefferalFee.protocolPart) > _protocolFee) {
            revert MultiswapRouter_InvalidFeeValue();
        }

        _refferalFee = newRefferalFee;
    }

    // =========================
    // Main logic
    // =========================

    function collectProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        uint256 balanceOf = profit[address(this)][token];
        if (balanceOf >= amount) {
            unchecked {
                profit[address(this)][token] -= amount;
            }
            HelperLib.safeTransfer(token, recipient, amount);
        }
    }

    function collectRefferalFees(address token, address recipient, uint256 amount) external {
        uint256 balanceOf = profit[msg.sender][token];

        if (balanceOf >= amount) {
            unchecked {
                profit[msg.sender][token] -= amount;
            }
            HelperLib.safeTransfer(token, recipient, amount);
        }
    }

    function collectProtocolFees(address token, address recipient) external onlyOwner {
        uint256 balanceOf = profit[address(this)][token];
        if (balanceOf >= 0) {
            unchecked {
                profit[address(this)][token] -= balanceOf;
            }
            HelperLib.safeTransfer(token, recipient, balanceOf);
        }
    }

    function collectRefferalFees(address token, address recipient) external {
        uint256 balanceOf = profit[msg.sender][token];

        if (balanceOf >= 0) {
            unchecked {
                profit[msg.sender][token] -= balanceOf;
            }
            HelperLib.safeTransfer(token, recipient, balanceOf);
        }
    }

    struct MultiswapCalldata {
        // initial exact value in
        uint256 amountIn;
        // minimal amountOut
        uint256 minAmountOut;
        // first token in swap
        address tokenIn;
        // array of bytes32 values (pairs) involved in the swap
        // from left to right:
        //     address of the pair - 20 bytes
        //     fee in pair - 3 bytes (for V2 pairs)
        //     the highest bit shows which version the pair belongs to
        bytes32[] pairs;
        // an optional address that slightly relaxes the protocol's fees in favor of that address 
        // and the user who called the multiswap
        address refferalAddress;
    }

    /// @notice Swaps through the data.pairs array
    function multiswap(MultiswapCalldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        uint256 lastIndex;
        unchecked {
            lastIndex = length - 1;
        }

        // if length of array is zero -> revert
        if (length == 0) {
            revert MultiswapRouter_InvalidPairsArray();
        }

        bytes32 pair = data.pairs[0];
        address firstPair;
        bool uni3;

        assembly {
            // take the first pair in the array
            firstPair := and(pair, ADDRESS_MASK)
            // find out which version of the protocol it belongs to
            uni3 := and(pair, UNISWAP_V3_MASK)
        }

        uint256 amountIn = data.amountIn;
        address tokenIn = data.tokenIn;

        // execute transferFrom:
        //     if the pair belongs to version 2 of the protocol - to the pair
        //     if version 3 - to the router contract
        HelperLib.safeTransferFrom(
            tokenIn, msg.sender, uni3 ? address(this) : firstPair, amountIn
        );

        uint256 balanceOutBeforeLastSwap;
        bool uni3Next;
        bytes32 destination;
        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            if (i == lastIndex) {
                // if the pair is the last in the array - the next token recipient after the swap is address(this)
                destination = ADDRESS_THIS_BYTES32;
            } else {
                // otherwise take the next pair
                destination = data.pairs[_unsafeAddOne(i)];
            }

            assembly {
                uni3 := and(pair, UNISWAP_V3_MASK)
                // if the next pair belongs to version 3 of the protocol - the address
                // of the router is set as the recipient, otherwise - the next pair
                uni3Next := and(destination, UNISWAP_V3_MASK)
            }

            if (uni3) {
                (amountIn, tokenIn, balanceOutBeforeLastSwap) = _swapUniV3(
                    i == lastIndex, pair, amountIn, tokenIn,
                    uni3Next ? ADDRESS_THIS_BYTES32 : destination
                );
            } else {
                (amountIn, tokenIn, balanceOutBeforeLastSwap) = _swapUniV2(
                    i == lastIndex, pair, tokenIn,
                    uni3Next ? ADDRESS_THIS_BYTES32 : destination
                );
            }
            // upgrade the pair for the next swap
            pair = destination;
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

        exactAmountOut = _writeFees( exactAmountOut, data.refferalAddress, tokenIn);

        HelperLib.safeTransfer(tokenIn, msg.sender, exactAmountOut);
    }

    // TODO
    struct PartswapCalldata {
        uint256 fullAmount;
        address tokenIn;
        uint256[] amountsIn;
        bytes32[] pairs;
    }

    // TODO
    function partSwap(PartswapCalldata calldata data) external {
        uint256 length = data.pairs.length;
        if (length == 0) {
            revert MultiswapRouter_InvalidPairsArray();
        }

        address tokenIn = data.tokenIn;

        HelperLib.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            data.fullAmount
        );

        bytes32 pair;
        bool uni3;
        bytes32 msgSenderBytes32;
        assembly {
            msgSenderBytes32 := caller()
        }

        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            pair = data.pairs[i];
            assembly {
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (uni3) {
                _swapUniV3(
                    false,
                    pair,
                    data.amountsIn[i],
                    tokenIn,
                    msgSenderBytes32
                );
            } else {
                address _pair;
                assembly {
                    _pair := and(pair, ADDRESS_MASK)
                }
                HelperLib.safeTransfer(tokenIn, _pair, data.amountsIn[i]);
                _swapUniV2(false, pair, tokenIn, msgSenderBytes32);
            }
        }
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

        assembly {
            amount0Delta := calldataload(4)
            amount1Delta := calldataload(36)
            tokenIn := calldataload(132)
        }

        // swaps entirely within 0-liquidity regions are not supported
        if (amount0Delta == 0 && amount1Delta == 0) {
            revert MultiswapRouter_FailedV3Swap();
        }

        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        // transfer tokens to the pool address
        HelperLib.safeTransfer(tokenIn, msg.sender, amountToPay);
    }

    // =========================
    // Private methods
    // =========================

    function _writeFees(uint256 exactAmount, address refferalAddress, address token) private returns (uint256) {
        if (refferalAddress == address(0)) {
            unchecked {
                uint256 fee = (exactAmount * _protocolFee) / FEE_MAX;
                profit[address(this)][token] += fee;

                return exactAmount - fee;
            }
        } else {
            unchecked {
                uint256 refferalFeePart = (exactAmount * _refferalFee.refferalPart) / FEE_MAX;
                uint256 protocolFeePart = (exactAmount * _refferalFee.protocolPart) / FEE_MAX;
                profit[refferalAddress][token] += refferalFeePart;
                profit[address(this)][token] += protocolFeePart;

                return exactAmount - refferalFeePart - protocolFeePart;
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
        private
        returns (uint256 amountOut, address tokenOut, uint256 balanceOutBeforeLastSwap)
    {
        IRouter pool;
        address destination;
        assembly {
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
        if (!(amountIn < CAST_INT_CONSTANT)) {
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
        private
        returns (uint256 amountOutput, address tokenOut, uint256 balanceOutBeforeLastSwap)
    {
        IRouter pair;
        uint256 fee;
        address destination;
        assembly {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(FEE_MASK, shr(160, _pair))
            destination := and(_destination, ADDRESS_MASK)
        }

        address token0 = pair.token0();
        tokenOut = tokenIn == token0 ? pair.token1() : token0;

        if (lastSwap) {
            balanceOutBeforeLastSwap = IERC20(tokenOut).balanceOf(address(this));
        }

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = tokenIn == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = IERC20(tokenIn).balanceOf(address(pair)) - reserveInput;
            }

            // get the output number of tokens after swap
            amountOutput = HelperLib.getAmountOut(
                amountInput, reserveInput, reserveOutput, fee
            );
        }

        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));

        if (
            // first do the swap via the most common swap function selector
            !_makeCall(
                address(pair),
                abi.encodeWithSelector(
                    // swap(uint256,uint256,address,bytes) selector
                    0x022c0d9f, amount0Out, amount1Out, destination, bytes("")
                )
            )
        ) {
            if (
                // if revert - try to swap through another selector
                !_makeCall(
                    address(pair),
                    abi.encodeWithSelector(
                        // swap(uint256,uint256,address) selector
                        0x6d9a640a, amount0Out, amount1Out, destination
                    )
                )
            ) {
                revert MultiswapRouter_FailedV2Swap();
            }
        }
    }

    /// @dev check for overflow has been removed for optimization
    function _unsafeAddOne(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @dev low-level call, returns true if successful
    function _makeCall(
        address addr,
        bytes memory data
    ) private returns (bool success) {
        (success, ) = addr.call(data);
    }
}
