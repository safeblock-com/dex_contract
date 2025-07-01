// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";
import { PoolHelper } from "../../libraries/PoolHelper.sol";
import { StorageLibrary, MultiswapRouterFacetStorage } from "../../libraries/StorageLibrary.sol";
import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";
import { FeeLibrary } from "../../libraries/FeeLibrary.sol";
import { E18, UNISWAP_V3_MASK, ADDRESS_MASK } from "../../libraries/Constants.sol";

import { IErrors } from "../../interfaces/IErrors.sol";
import { IWrappedNative } from "../../interfaces/IWrappedNative.sol";

import { IMultiswapRouterFacet } from "./interfaces/IMultiswapRouterFacet.sol";

/// @title MultiswapRouterFacet
/// @notice A facet for executing multi-path swaps across Uniswap V2 and V3 pools in a diamond-like proxy contract.
/// @dev Supports complex swaps with multiple pools, token wrapping, and fee payments, integrating with Uniswap V2/V3 protocols.
contract MultiswapRouterFacet is IMultiswapRouterFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the Wrapped Native token contract (e.g., WETH).
    ///      Immutable, set during construction. Used in `_wrapNative` to convert native currency to wrapped tokens.
    IWrappedNative private immutable _wrappedNative;

    /// @dev The address of this contract.
    ///      Immutable, set during construction.
    address private immutable _self;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the MultiswapRouterFacet with the Wrapped Native token address.
    /// @dev Sets the immutable `_wrappedNative` and `_self` addresses.
    /// @param wrappedNative_ The address of the Wrapped Native token contract.
    constructor(address wrappedNative_) {
        _wrappedNative = IWrappedNative(wrappedNative_);
        _self = address(this);
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
            revert IErrors.MultiswapRouterFacet_InvalidPairsArray();
        }

        Utils.expectEqual(length, data.amountInPercentages.length);

        address[] calldata tokensOut = data.tokensOut;
        Utils.expectEqual(tokensOut.length, data.minAmountsOut.length);

        uint256 fullAmount = data.fullAmount;
        address tokenIn;
        unchecked {
            uint256 amountInPercentagesCheck;
            for (uint256 i; i < length; ++i) {
                amountInPercentagesCheck += data.amountInPercentages[i];
            }

            // sum of percentages array must be equal to 100% (1e18)
            Utils.expectEqual(amountInPercentagesCheck, E18);

            (tokenIn,) = _wrapNative(data.tokenIn, fullAmount);
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

                fullAmount = Utils.compareAmounts(
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) }), balanceInBeforeTransfer
                );
                fullAmount -= FeeLibrary.payFee({ token: tokenIn, amount: fullAmount });
            } else {
                fullAmount = amount - FeeLibrary.payFee({ token: tokenIn, amount: amount });
            }
        }

        uint256[] memory amountsOut = new uint256[](tokensOut.length);

        unchecked {
            uint256 lastIndex = length - 1;

            uint256 remainingAmount = fullAmount;
            uint256 amountIn;
            for (uint256 i; i < length; i = ++i) {
                if (i == lastIndex) {
                    amountIn = remainingAmount;
                } else {
                    amountIn = fullAmount * data.amountInPercentages[i] / E18;
                    remainingAmount -= amountIn;
                }

                (uint256 amountOut, address tokenOut) = _multiswap(data.pairs[i], amountIn, tokenIn);

                bool added;
                for (uint256 j = tokensOut.length; j > 0;) {
                    --j;

                    if (tokensOut[j] == tokenOut) {
                        amountsOut[j] += amountOut;
                        added = true;
                        break;
                    }
                }
                if (!added) {
                    revert IErrors.MultiswapRouterFacet_InvalidMultiswap2Calldata();
                }
            }
        }

        for (uint256 i = amountsOut.length; i > 0;) {
            unchecked {
                --i;
            }
            Utils.compareAmounts(amountsOut[i], data.minAmountsOut[i]);
            TransientStorageFacetLibrary.setAmountForToken({ token: tokensOut[i], amount: amountsOut[i], record: true });
        }
    }

    /// @inheritdoc IMultiswapRouterFacet
    function multiswap2Reverse(IMultiswapRouterFacet.Multiswap2Calldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            revert IErrors.MultiswapRouterFacet_InvalidPairsArray();
        }
        Utils.expectEqual(length, data.tokensOut.length);
        Utils.expectEqual(length, data.minAmountsOut.length);

        uint256[] calldata tokensOut = data.amountInPercentages;

        uint256 fullAmount = data.fullAmount;

        address tokenIn;
        bool wrap;
        {
            (tokenIn, wrap) = _wrapNative(data.tokenIn, fullAmount);
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

                fullAmount = Utils.compareAmounts(
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) }), balanceInBeforeTransfer
                );
            } else {
                fullAmount = amount;
            }
        }

        if (fullAmount == 0) {
            revert IErrors.MultiswapRouterFacet_InvalidAmountIn();
        }

        uint256[] memory amountsOut = new uint256[](tokensOut.length);

        unchecked {
            uint256 sumAmountIn;
            for (uint256 i; i < length; i = ++i) {
                address tokenOut = data.tokensOut[i];

                (uint256 amountIn, uint256 amountOut) =
                    _multiswapReverse(tokenIn, data.minAmountsOut[i], data.pairs[i], tokenOut);

                bool added;
                for (uint256 j = tokensOut.length; j > 0;) {
                    --j;

                    if (Utils.uintToAddress(tokensOut[j]) == tokenOut) {
                        amountsOut[j] += amountOut;
                        added = true;
                        break;
                    }
                }

                if (!added) {
                    revert IErrors.MultiswapRouterFacet_InvalidMultiswap2Calldata();
                }

                sumAmountIn += amountIn;
            }

            uint256 remaining = Utils.compareAmounts(
                fullAmount, sumAmountIn + FeeLibrary.payFee({ token: tokenIn, amount: sumAmountIn })
            );
            if (remaining > 0) {
                if (wrap) {
                    _wrappedNative.withdraw({ wad: remaining });
                    TransferHelper.safeTransferNative({
                        to: TransientStorageFacetLibrary.getSenderAddress(),
                        value: remaining
                    });
                } else {
                    TransferHelper.safeTransfer({
                        token: tokenIn,
                        to: TransientStorageFacetLibrary.getSenderAddress(),
                        value: remaining
                    });
                }
            }
        }

        for (uint256 len = amountsOut.length; len > 0;) {
            unchecked {
                --len;
            }
            TransientStorageFacetLibrary.setAmountForToken({
                token: Utils.uintToAddress(tokensOut[len]),
                amount: amountsOut[len],
                record: true
            });
        }
    }

    /// @notice Handles swap callbacks.
    /// @dev Validates the caller against the cached pool address, processes swap deltas, and transfers tokens to the pool.
    ///      Reverts with `MultiswapRouterFacet_SenderMustBePool` if the caller
    ///      is invalid or `MultiswapRouterFacet_FailedV3Swap` if the swap has no liquidity.
    fallback() external {
        MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
        uint256 swapType;
        uint256 pathLength;

        // Checking that msg.sender is equal to the value from the cache
        // and zeroing the storage
        assembly ("memory-safe") {
            let sender := sload(s.slot)
            swapType := and(shr(160, sender), 0xff)
            pathLength := shr(168, sender)
            sender := and(sender, ADDRESS_MASK)

            sstore(s.slot, 0)

            if sub(caller(), sender) {
                // IErrors.MultiswapRouterFacet_SenderMustBePool()
                mstore(0, 0x990dbec2)
                revert(28, 4)
            }
        }

        int256 amount0Delta;
        int256 amount1Delta;
        if (swapType == 0) {
            address tokenIn;

            assembly ("memory-safe") {
                amount0Delta := calldataload(4)
                amount1Delta := calldataload(36)
                tokenIn := calldataload(132)
            }

            // swaps entirely within 0-liquidity regions are not supported
            if (amount0Delta == 0 && amount1Delta == 0) {
                revert IErrors.MultiswapRouterFacet_FailedV3Swap();
            }

            uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

            // transfer tokens to the pool address
            TransferHelper.safeTransfer({ token: tokenIn, to: msg.sender, value: amountToPay });
        } else {
            uint256 amountOut;
            address tokenOut;
            bytes32[] memory path;

            assembly ("memory-safe") {
                let cDataOffset := sub(calldatasize(), add(128, mul(32, pathLength)))

                switch swapType
                case 1 { amountOut := calldataload(cDataOffset) }
                default {
                    amount0Delta := calldataload(4)
                    amount1Delta := calldataload(36)
                }

                tokenOut := calldataload(add(cDataOffset, 32))

                pathLength := sub(pathLength, 1)

                if pathLength {
                    mstore(path, pathLength)
                    let size := mul(32, pathLength)
                    calldatacopy(add(path, 32), add(cDataOffset, 128), size)

                    mstore(64, add(path, add(32, size)))
                }
            }

            if (swapType == 2) {
                // swaps entirely within 0-liquidity regions are not supported
                if (amount0Delta == 0 && amount1Delta == 0) {
                    revert IErrors.MultiswapRouterFacet_FailedV3Swap();
                }

                amountOut = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
            }

            if (pathLength == 0) {
                TransferHelper.safeTransfer({ token: tokenOut, to: msg.sender, value: amountOut });
            } else {
                unchecked {
                    bytes32 pair = path[pathLength - 1];
                    bool uni3;

                    assembly ("memory-safe") {
                        uni3 := and(pair, UNISWAP_V3_MASK)
                    }

                    if (uni3) {
                        PoolHelper.swapUniV3ExactOut({
                            callbackAddress: _self,
                            amountOut: amountOut,
                            tokenOut: tokenOut,
                            _pool: pair,
                            destination: msg.sender,
                            path: path
                        });
                    } else {
                        PoolHelper.swapUniV2ExactOut({
                            callbackAddress: _self,
                            _pair: pair,
                            tokenOut: tokenOut,
                            destination: address(this),
                            amountOut: amountOut,
                            path: path
                        });
                        TransferHelper.safeTransfer({ token: tokenOut, to: msg.sender, value: amountOut });
                    }
                }
            }
        }
    }

    // =========================
    // internal methods
    // =========================

    /// @dev Executes a swap through a sequence of Uniswap V2 or V3 pools.
    ///      Iterates over the provided pairs, performing swaps and updating the token and amount.
    ///      Reverts with `MultiswapRouterFacet_InvalidAmountIn` if the input amount is zero.
    /// @param pairs The array of pool identifiers (encoded with protocol version, address, and fee).
    /// @param amountIn The input amount for the first swap.
    /// @param tokenIn The input token for the first swap.
    /// @return amountOut The final output amount after all swaps.
    /// @return tokenOut The final output token after all swaps.
    function _multiswap(
        bytes32[] calldata pairs,
        uint256 amountIn,
        address tokenIn
    )
        internal
        returns (uint256, address)
    {
        if (amountIn == 0) {
            revert IErrors.MultiswapRouterFacet_InvalidAmountIn();
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
        unchecked {
            uint256 lastIndex = length - 1;

            bytes32 addressThisBytes32 = Utils.addressThisBytes32();
            bool uni3Next;
            bytes32 destination;
            for (uint256 i; i < length; i = ++i) {
                if (i == lastIndex) {
                    // if the pair is the last in the array - the next token recipient after the swap is address(this)
                    destination = addressThisBytes32;
                    uni3Next = true;
                } else {
                    // otherwise take the next pair
                    destination = pairs[i + 1];

                    assembly ("memory-safe") {
                        // if the next pair belongs to version 3 of the protocol - the address
                        // of the router is set as the recipient, otherwise - the next pair
                        uni3Next := and(destination, UNISWAP_V3_MASK)
                    }
                }

                if (uni3) {
                    (amountIn, tokenIn) = PoolHelper.swapUniV3ExactIn({
                        callbackAddress: _self,
                        amountIn: amountIn,
                        tokenIn: tokenIn,
                        _pool: pair,
                        _destination: uni3Next ? addressThisBytes32 : destination,
                        destinationIsAddressThis: uni3Next
                    });
                } else {
                    (amountIn, tokenIn) = PoolHelper.swapUniV2ExactIn({
                        _pair: pair,
                        tokenIn: tokenIn,
                        _destination: uni3Next ? addressThisBytes32 : destination,
                        destinationIsAddressThis: uni3Next
                    });
                }

                // upgrade the pair for the next swap
                pair = destination;
                uni3 = uni3Next;
            }
        }

        return (amountIn, tokenIn);
    }

    /// @dev Executes a swap through a sequence of Uniswap V2 or V3 pools in reverse order.
    ///      Starts from the last pair and swap in callbacks through the all pairs.
    /// @param pairs The array of pool identifiers (encoded with protocol version, address, and fee).
    /// @param amountOut The exact output amount for the swap.
    /// @param tokenIn The input token for the first swap.
    /// @param tokenOut The final output token after all swaps.
    /// @return The exact amountIn and amountOut for the swap.
    function _multiswapReverse(
        address tokenIn,
        uint256 amountOut,
        bytes32[] calldata pairs,
        address tokenOut
    )
        internal
        returns (uint256, uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = pairs.length;
        // if length of array is zero -> returns amountOut and tokenOut
        if (length == 0) {
            return (amountOut, amountOut);
        }

        uint256 balanceInBeforeSwap = TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) });
        uint256 balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });

        // scope for swaps, avoids stack too deep errors
        {
            bytes32 pair;
            unchecked {
                pair = pairs[length - 1];
            }

            bool uni3;

            assembly ("memory-safe") {
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (uni3) {
                PoolHelper.swapUniV3ExactOut({
                    callbackAddress: _self,
                    amountOut: amountOut,
                    tokenOut: tokenOut,
                    _pool: pair,
                    destination: address(this),
                    path: pairs
                });
            } else {
                PoolHelper.swapUniV2ExactOut({
                    callbackAddress: _self,
                    _pair: pair,
                    tokenOut: tokenOut,
                    destination: address(this),
                    amountOut: amountOut,
                    path: pairs
                });
            }
        }

        return (
            // return the exact amountIn of tokens as a result of the swap
            Utils.compareAmounts(
                balanceInBeforeSwap, TransferHelper.safeGetBalance({ token: tokenIn, account: address(this) })
            ),
            // and return the exact amountOut of tokens as a result of the swap
            Utils.compareAmounts(
                TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }), balanceOutBeforeSwap
            )
        );
    }

    /// @dev Wraps native currency to Wrapped Native tokens if the input token is native.
    ///      Deposits native currency to the Wrapped Native contract and records the amount in `TransientStorageFacetLibrary`.
    /// @param tokenIn The input token address (or address(0) for native currency).
    /// @param amount The amount to wrap.
    /// @return The token address (Wrapped Native if native currency was input) and a boolean indicating if native currency was input.
    function _wrapNative(address tokenIn, uint256 amount) internal returns (address, bool) {
        if (tokenIn == address(0)) {
            _wrappedNative.deposit{ value: amount }();

            TransientStorageFacetLibrary.setAmountForToken({
                token: address(_wrappedNative),
                amount: amount,
                record: false
            });

            return (address(_wrappedNative), true);
        }

        return (tokenIn, false);
    }
}
