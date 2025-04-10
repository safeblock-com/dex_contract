// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "./BaseOwnableFacet.sol";

import { IUniswapPool } from "../interfaces/IUniswapPool.sol";
import { HelperLib } from "./libraries/HelperLib.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";

import { IMultiswapRouterFacet } from "./interfaces/IMultiswapRouterFacet.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

import { TransientStorageFacetLibrary } from "../libraries/TransientStorageFacetLibrary.sol";
import { FeeLibrary } from "../libraries/FeeLibrary.sol";
import { PoolHelper } from "./libraries/PoolHelper.sol";

import { IFeeContract } from "../interfaces/IFeeContract.sol";

import {
    E18,
    UNISWAP_V3_MASK,
    ADDRESS_MASK,
    FEE_MASK,
    MIN_SQRT_RATIO_PLUS_ONE,
    MAX_SQRT_RATIO_MINUS_ONE,
    CAST_INT_CONSTANT
} from "../libraries/Constants.sol";

/// @title Multiswap Router Facet
/// @notice Router for UniswapV3 and UniswapV2 multiswaps and partswaps
contract MultiswapRouterFacet is BaseOwnableFacet, IMultiswapRouterFacet {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    IWrappedNative private immutable _wrappedNative;

    address private immutable _self;

    struct MultiswapRouterFacetStorage {
        /// @dev cache for swapV3Callback
        address poolAddressCache;
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

    // =========================
    // main logic
    // =========================

    /// @inheritdoc IMultiswapRouterFacet
    function multiswap2(IMultiswapRouterFacet.Multiswap2Calldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray();
        }
        if (length != data.amountInPercentages.length) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata();
        }

        address[] calldata tokensOut = data.tokensOut;
        if (tokensOut.length != data.minAmountsOut.length) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata();
        }

        uint256 fullAmount = data.fullAmount;
        address tokenIn;
        {
            uint256 amountInPercentagesCheck;
            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                unchecked {
                    amountInPercentagesCheck += data.amountInPercentages[i];
                }
            }

            // sum of amounts array must be equal to 100% (1e18)
            if (amountInPercentagesCheck != E18) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata();
            }

            tokenIn = _wrapNative(data.tokenIn, fullAmount);
            uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: tokenIn });
            if (amount == 0) {
                uint256 balanceInBeforeTransfer =
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) });

                // Transfer full amountIn for all swaps
                TransferHelper.safeTransferFrom({
                    token: tokenIn,
                    from: TransientStorageFacetLibrary.getSenderAddress(),
                    to: address(this),
                    value: fullAmount
                });

                uint256 balanceInAfterTransfer =
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) });

                _checkOutputAmount(balanceInAfterTransfer, balanceInBeforeTransfer);

                unchecked {
                    // for tokens with transfer fee we need to update fullAmount after transfer and get exact amount
                    // which has been transferred to the contract
                    fullAmount = _payFeeIfNecessary(tokenIn, balanceInAfterTransfer - balanceInBeforeTransfer, 0);
                }
            } else {
                fullAmount = _payFeeIfNecessary(tokenIn, amount, 0);
            }
        }

        uint256[] memory amountsOut = new uint256[](tokensOut.length);

        {
            uint256 lastIndex;
            unchecked {
                lastIndex = length - 1;
            }

            uint256 remainingAmount = fullAmount;
            uint256 amountIn;
            for (uint256 i; i < length; i = _unsafeAddOne(i)) {
                if (i == lastIndex) {
                    amountIn = remainingAmount;
                } else {
                    unchecked {
                        amountIn = fullAmount * data.amountInPercentages[i] / E18;
                        remainingAmount -= amountIn;
                    }
                }

                (uint256 amountOut, address tokenOut) = _multiswap(data.pairs[i], amountIn, tokenIn);

                bool added;
                for (uint256 j = tokensOut.length; j > 0;) {
                    unchecked {
                        --j;

                        if (tokensOut[j] == tokenOut) {
                            amountsOut[j] += amountOut;
                            added = true;
                            break;
                        }
                    }
                }
                if (!added) {
                    revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata();
                }
            }
        }

        for (uint256 len = amountsOut.length; len > 0;) {
            unchecked {
                --len;
            }
            address tokenOut = tokensOut[len];
            TransientStorageFacetLibrary.setAmountForToken({
                token: tokenOut,
                amount: _payFeeIfNecessary(tokenOut, amountsOut[len], data.minAmountsOut[len]),
                record: true
            });
        }
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
        bytes32[] calldata pairs,
        uint256 amountIn,
        address tokenIn
    )
        internal
        returns (uint256, address)
    {
        if (amountIn == 0) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn();
        }

        // cache length of pairs to stack for gas savings
        uint256 length = pairs.length;
        // if length of array is zero -> returns amountIn and tokenIn
        if (length == 0) {
            return (amountIn, tokenIn);
        }

        bytes32 pair = pairs[0];
        bool uni3;

        // scope for transfer, avoids stack too deep errors
        {
            address firstPair;
            assembly ("memory-safe") {
                // take the first pair in the array
                firstPair := and(pair, ADDRESS_MASK)
                // find out which version of the protocol it belongs to
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (!uni3) {
                // execute transfer:
                //     if the pair belongs to version 2 of the protocol -> transfer tokens to the pair
                TransferHelper.safeTransfer({ token: tokenIn, to: firstPair, value: amountIn });
            }
        }

        // scope for swaps, avoids stack too deep errors
        {
            uint256 lastIndex;
            unchecked {
                lastIndex = length - 1;
            }

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
                    destination = pairs[_unsafeAddOne(i)];

                    assembly ("memory-safe") {
                        // if the next pair belongs to version 3 of the protocol - the address
                        // of the router is set as the recipient, otherwise - the next pair
                        uni3Next := and(destination, UNISWAP_V3_MASK)
                    }
                }

                if (uni3) {
                    (amountIn, tokenIn) =
                        _swapUniV3(amountIn, tokenIn, pair, uni3Next ? addressThisBytes32 : destination, uni3Next);
                } else {
                    (amountIn, tokenIn) =
                        _swapUniV2(pair, tokenIn, uni3Next ? addressThisBytes32 : destination, uni3Next);
                }

                // upgrade the pair for the next swap
                pair = destination;
                uni3 = uni3Next;
            }
        }

        return (amountIn, tokenIn);
    }

    /// @dev uniswapV3 swap exact tokens
    function _swapUniV3(
        uint256 amountIn,
        address tokenIn,
        bytes32 _pool,
        bytes32 _destination,
        bool destinationIsAddressThis
    )
        internal
        returns (uint256 amountOut, address tokenOut)
    {
        IUniswapPool pool;
        address destination;
        assembly ("memory-safe") {
            pool := and(_pool, ADDRESS_MASK)
            destination := and(_destination, ADDRESS_MASK)
        }

        bool zeroForOne;
        (zeroForOne, tokenOut) = PoolHelper.validateTokenInPair(pool, tokenIn);

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
        IUniswapPool pair;
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
        (tokenInIsToken0, tokenOut) = PoolHelper.validateTokenInPair(pair, tokenIn);

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserveInput, uint256 reserveOutput) = PoolHelper.getReserves(pair, tokenInIsToken0);

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

    /// @dev check output amount and pay fee to FeeContract if necessary
    function _payFeeIfNecessary(
        address tokenOut,
        uint256 amountOut,
        uint256 minAmountOut
    )
        internal
        returns (uint256 amount)
    {
        _checkOutputAmount(amountOut, minAmountOut);

        amount = FeeLibrary.payFee({ token: tokenOut, amount: amountOut });
    }

    /// @dev low-level call, returns true if successful
    function _makeCall(address addr, bytes memory data) internal returns (bool success) {
        (success,) = addr.call(data);
    }

    /// @dev wraps native token if needed
    function _wrapNative(address tokenIn, uint256 amount) internal returns (address _tokenIn) {
        if (tokenIn == address(0)) {
            if (address(this).balance < amount) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn();
            }

            _wrappedNative.deposit{ value: amount }();

            TransientStorageFacetLibrary.setAmountForToken({
                token: address(_wrappedNative),
                amount: amount,
                record: false
            });

            return address(_wrappedNative);
        }

        return tokenIn;
    }
}
