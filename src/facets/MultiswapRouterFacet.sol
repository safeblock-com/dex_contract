// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "./BaseOwnableFacet.sol";

import { IRouter } from "./interfaces/IRouter.sol";
import { HelperLib } from "./libraries/HelperLib.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";

import { IMultiswapRouterFacet } from "./interfaces/IMultiswapRouterFacet.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

import { TransientStorageFacetLibrary } from "../libraries/TransientStorageFacetLibrary.sol";

import { IFeeContract } from "../interfaces/IFeeContract.sol";

/// @title Multiswap Router Facet
/// @notice Router for UniswapV3 and UniswapV2 multiswaps and partswaps
contract MultiswapRouterFacet is BaseOwnableFacet, IMultiswapRouterFacet {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    IWrappedNative private immutable _wrappedNative;

    address private immutable _self;

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

    struct MultiswapRouterFacetStorage {
        /// @dev cache for swapV3Callback
        address poolAddressCache;
        IFeeContract feeContract;
    }

    /// @dev Storage position for the multiswap router facet, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    // keccak256("multiswap.router.storage")
    bytes32 private constant MULTISWAP_ROUTER_FACET_STORAGE =
        0x73a3a170c596aa083fa5166abc0f3239e53b41143f45c8bd25a602694c09d735;

    /// @dev Returns the storage slot for the multiswapRouterFacet.
    /// @dev This function utilizes inline assembly to directly access the desired storage position.
    ///
    /// @return s The storage slot pointer for the multiswapRouterFacet.
    function _getLocalStorage() internal pure returns (MultiswapRouterFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := MULTISWAP_ROUTER_FACET_STORAGE
        }
    }

    // =========================
    // constructor
    // =========================

    constructor(address wrappedNative_) {
        _wrappedNative = IWrappedNative(wrappedNative_);

        _self = address(this);
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc IMultiswapRouterFacet
    function wrappedNative() external view returns (address) {
        return address(_wrappedNative);
    }

    /// @inheritdoc IMultiswapRouterFacet
    function feeContract() external view returns (address) {
        return address(_getLocalStorage().feeContract);
    }

    // =========================
    // admin logic
    // =========================

    /// @inheritdoc IMultiswapRouterFacet
    function setFeeContract(address newFeeContract) external onlyOwner {
        _getLocalStorage().feeContract = IFeeContract(newFeeContract);
    }

    // =========================
    // main logic
    // =========================

    /// @inheritdoc IMultiswapRouterFacet
    function multiswap(IMultiswapRouterFacet.MultiswapCalldata calldata data)
        external
        payable
        returns (uint256 amount)
    {
        bool isNative = _wrapNative(data.tokenIn, data.amountIn);

        amount = _multiswap(isNative, data);
    }

    /// @inheritdoc IMultiswapRouterFacet
    function partswap(IMultiswapRouterFacet.PartswapCalldata calldata data) external payable returns (uint256 amount) {
        address tokenIn = data.tokenIn;
        uint256 fullAmount = data.fullAmount;
        bool isNative = _wrapNative(tokenIn, fullAmount);

        amount = _partswap(isNative, fullAmount, isNative ? address(_wrappedNative) : tokenIn, data);
    }

    // for V3Callback
    fallback() external {
        MultiswapRouterFacetStorage storage s = _getLocalStorage();

        // Checking that msg.sender is equal to the value from the cache
        // and zeroing the storage
        if (msg.sender != s.poolAddressCache) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_SenderMustBeUniswapV3Pool();
        }
        s.poolAddressCache = address(0);

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
            revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap();
        }

        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        // transfer tokens to the pool address
        TransferHelper.safeTransfer({ token: tokenIn, to: msg.sender, value: amountToPay });
    }

    // =========================
    // internal methods
    // =========================

    /// @dev Swaps through the data.pairs array
    function _multiswap(
        bool isNative,
        IMultiswapRouterFacet.MultiswapCalldata calldata data
    )
        internal
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray();
        }

        uint256 lastIndex;
        unchecked {
            lastIndex = length - 1;
        }

        bytes32 pair = data.pairs[0];
        bool uni3;

        address tokenIn;
        uint256 amountIn = data.amountIn;

        if (amountIn == 0) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn();
        }

        // scope for transfer, avoids stack too deep errors
        {
            address firstPair;

            assembly ("memory-safe") {
                // take the first pair in the array
                firstPair := and(pair, ADDRESS_MASK)
                // find out which version of the protocol it belongs to
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (isNative) {
                tokenIn = address(_wrappedNative);

                // execute transfer:
                //     if the pair belongs to version 2 of the protocol -> transfer tokens to the pair
                if (!uni3) {
                    TransferHelper.safeTransfer({ token: tokenIn, to: firstPair, value: amountIn });
                }
            } else {
                tokenIn = data.tokenIn;

                if (TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) }) < amountIn) {
                    // execute transferFrom:
                    //     if the pair belongs to version 2 of the protocol -> transfer tokens to the pair
                    //     if version 3 -> to this contract
                    TransferHelper.safeTransferFrom({
                        token: tokenIn,
                        from: TransientStorageFacetLibrary.getSenderAddress(),
                        to: uni3 ? address(this) : firstPair,
                        value: amountIn
                    });
                } else if (!uni3) {
                    // execute transfer:
                    //     if the pair belongs to version 2 of the protocol -> transfer tokens to the pair
                    TransferHelper.safeTransfer({ token: tokenIn, to: firstPair, value: amountIn });
                }
            }
        }

        // scope for swaps, avoids stack too deep errors
        {
            bytes32 addressThisBytes32 = _addressThisBytes32();
            bool uni3Next;
            bytes32 destination;
            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                if (i == lastIndex) {
                    // if the pair is the last in the array - the next token recipient after the swap is address(this)
                    destination = addressThisBytes32;
                    uni3Next = true;
                } else {
                    // otherwise take the next pair
                    destination = data.pairs[_unsafeAddOne(i)];

                    assembly ("memory-safe") {
                        // if the next pair belongs to version 3 of the protocol - the address
                        // of the router is set as the recipient, otherwise - the next pair
                        uni3Next := and(destination, UNISWAP_V3_MASK)
                    }
                }

                if (uni3) {
                    (amountIn, tokenIn) =
                        _swapUniV3(pair, amountIn, tokenIn, uni3Next ? addressThisBytes32 : destination, uni3Next);
                } else {
                    (amountIn, tokenIn) =
                        _swapUniV2(pair, tokenIn, uni3Next ? addressThisBytes32 : destination, uni3Next);
                }

                // upgrade the pair for the next swap
                pair = destination;
                uni3 = uni3Next;
            }
        }

        _checkOutputAmount(amountIn, data.minAmountOut);

        {
            IFeeContract _feeContract = _getLocalStorage().feeContract;
            if (address(_feeContract) != address(0)) {
                uint256 fee = _feeContract.writeFees({ token: tokenIn, amount: amountIn });

                if (fee > 0) {
                    TransferHelper.safeTransfer({ token: tokenIn, to: address(_feeContract), value: fee });

                    unchecked {
                        amountIn -= fee;
                    }
                }
            }
        }

        return amountIn;
    }

    /// @dev Swaps tokenIn through each pair separately
    function _partswap(
        bool isNative,
        uint256 fullAmount,
        address tokenIn,
        IMultiswapRouterFacet.PartswapCalldata calldata data
    )
        internal
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray();
        }
        if (length != data.amountsIn.length) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata();
        }

        address sender = TransientStorageFacetLibrary.getSenderAddress();
        {
            uint256 fullAmountCheck;
            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                unchecked {
                    fullAmountCheck += data.amountsIn[i];
                }
            }

            // sum of amounts array must be lte to fullAmount
            if (fullAmountCheck > fullAmount) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata();
            }

            if (!isNative) {
                uint256 balanceInBeforeTransfer =
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) });

                if (balanceInBeforeTransfer < fullAmount) {
                    // Transfer full amountIn for all swaps
                    TransferHelper.safeTransferFrom({
                        token: tokenIn,
                        from: sender,
                        to: address(this),
                        value: fullAmount
                    });

                    uint256 amountInAfterTransfer =
                        TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) });

                    _checkOutputAmount(amountInAfterTransfer, balanceInBeforeTransfer);

                    unchecked {
                        fullAmount = amountInAfterTransfer - balanceInBeforeTransfer;
                    }
                }
            }
        }

        bytes32 addressThisBytes32 = _addressThisBytes32();

        bytes32 pair;
        bool uni3;

        uint256 exactAmountOut = TransferHelper.safeGetBalance({ token: data.tokenOut, account: address(this) });
        {
            uint256 remain = fullAmount;

            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                pair = data.pairs[i];
                assembly ("memory-safe") {
                    uni3 := and(pair, UNISWAP_V3_MASK)
                }

                uint256 amountIn = data.amountsIn[i];

                if (remain < amountIn) {
                    amountIn = remain;
                }

                unchecked {
                    remain -= amountIn;
                }

                if (amountIn > 0) {
                    if (uni3) {
                        _swapUniV3(pair, amountIn, tokenIn, addressThisBytes32, false);
                    } else {
                        address _pair;
                        assembly ("memory-safe") {
                            _pair := and(pair, ADDRESS_MASK)
                        }
                        TransferHelper.safeTransfer({ token: tokenIn, to: _pair, value: amountIn });
                        _swapUniV2(pair, tokenIn, addressThisBytes32, false);
                    }
                }

                if (remain == 0) {
                    break;
                }
            }

            if (remain > 0) {
                TransferHelper.safeTransfer({ token: tokenIn, to: sender, value: remain });
            }
        }

        address tokenOut = data.tokenOut;
        unchecked {
            exactAmountOut = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }) - exactAmountOut;
        }

        _checkOutputAmount(exactAmountOut, data.minAmountOut);

        {
            IFeeContract _feeContract = _getLocalStorage().feeContract;
            if (address(_feeContract) != address(0)) {
                uint256 fee = _feeContract.writeFees({ token: tokenOut, amount: exactAmountOut });

                if (fee > 0) {
                    TransferHelper.safeTransfer({ token: tokenOut, to: address(_feeContract), value: fee });

                    unchecked {
                        exactAmountOut -= fee;
                    }
                }
            }
        }

        return exactAmountOut;
    }

    /// @dev uniswapV3 swap exact tokens
    function _swapUniV3(
        bytes32 _pool,
        uint256 amountIn,
        address tokenIn,
        bytes32 _destination,
        bool destinationIsAddressThis
    )
        internal
        returns (uint256 amountOut, address tokenOut)
    {
        IRouter pool;
        address destination;
        assembly ("memory-safe") {
            pool := and(_pool, ADDRESS_MASK)
            destination := and(_destination, ADDRESS_MASK)
        }

        bool zeroForOne;
        (zeroForOne, tokenOut) = _validateTokenInPair(pool, tokenIn);

        // cast a uint256 to a int256, revert on overflow
        // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol#L24
        if (amountIn > CAST_INT_CONSTANT) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidIntCast();
        }

        // caching pool address and callback address in storage
        _getLocalStorage().poolAddressCache = address(pool);
        TransientStorageFacetLibrary.setCallbackAddress({ callbackAddress: _self });

        uint256 balanceOutBeforeSwap;
        if (destinationIsAddressThis) {
            balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });
        }

        pool.swap({
            recipient: destination,
            zeroForOne: zeroForOne,
            amountSpecified: int256(amountIn),
            sqrtPriceLimitX96: (zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            data: abi.encode(tokenIn)
        });

        if (destinationIsAddressThis) {
            uint256 balanceOutAfterSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });
            _checkOutputAmount(balanceOutAfterSwap, balanceOutBeforeSwap);

            unchecked {
                // return the exact amount of tokens as a result of the swap
                amountOut = balanceOutAfterSwap - balanceOutBeforeSwap;
            }
        }
    }

    /// @dev uniswapV2 swap exact tokens
    function _swapUniV2(
        bytes32 _pair,
        address tokenIn,
        bytes32 _destination,
        bool destinationIsAddressThis
    )
        internal
        returns (uint256 amountOut, address tokenOut)
    {
        IRouter pair;
        uint256 isSolidly;
        address destination;
        uint256 fee;
        assembly ("memory-safe") {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(shr(160, _pair), FEE_MASK)
            destination := and(_destination, ADDRESS_MASK)
            isSolidly := and(shr(184, _pair), 0xff)
        }

        bool tokenInIsToken0;
        (tokenInIsToken0, tokenOut) = _validateTokenInPair(pair, tokenIn);

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            uint256 reserveInput;
            uint256 reserveOutput;
            {
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (reserveInput, reserveOutput) = tokenInIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
            }

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = TransferHelper.safeGetBalance({ token: tokenIn, account: address(pair) }) - reserveInput;
            }

            if (isSolidly == 0) {
                // get the output number of tokens after swap
                amountOut = HelperLib.getAmountOut({
                    amountIn: amountInput,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: fee
                });
            } else {
                amountOut = pair.getAmountOut({ amountIn: amountInput, tokenIn: tokenIn });
            }
        }

        (uint256 amount0Out, uint256 amount1Out) = tokenInIsToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

        uint256 balanceOutBeforeSwap;
        if (destinationIsAddressThis) {
            balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });
        }

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
                revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV2Swap();
            }
        }

        if (destinationIsAddressThis) {
            uint256 balanceOutAfterSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });
            _checkOutputAmount(balanceOutAfterSwap, balanceOutBeforeSwap);

            unchecked {
                // return the exact amount of tokens as a result of the swap
                amountOut = balanceOutAfterSwap - balanceOutBeforeSwap;
            }
        }
    }

    /// @dev check if tokenIn is token0 or token1 and return tokenOut
    function _validateTokenInPair(
        IRouter pair,
        address tokenIn
    )
        internal
        view
        returns (bool tokenInIsToken0, address tokenOut)
    {
        address token0 = pair.token0();

        // if token0 in the pair is tokenIn -> tokenOut == token1, otherwise tokenOut == token0
        if (token0 == tokenIn) {
            tokenInIsToken0 = true;
            tokenOut = pair.token1();
        } else {
            if (tokenIn != pair.token1()) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn();
            }

            tokenOut = token0;
        }
    }

    /// @dev check balance after swap
    function _checkOutputAmount(uint256 greaterBalance, uint256 lowerBalance) internal pure {
        if (greaterBalance < lowerBalance) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut();
        }
    }

    /// @dev check for overflow has been removed for optimization
    function _unsafeAddOne(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @dev returns address(this) in bytes32 format
    function _addressThisBytes32() internal view returns (bytes32 addressThisBytes32) {
        assembly ("memory-safe") {
            addressThisBytes32 := address()
        }
    }

    /// @dev low-level call, returns true if successful
    function _makeCall(address addr, bytes memory data) internal returns (bool success) {
        (success,) = addr.call(data);
    }

    /// @dev wraps native token if needed
    function _wrapNative(address tokenIn, uint256 amount) internal returns (bool isNative) {
        isNative = tokenIn == address(0);

        if (isNative) {
            if (address(this).balance < amount) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn();
            }

            _wrappedNative.deposit{ value: amount }();
        }
    }
}
