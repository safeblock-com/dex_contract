// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";
import { RouterHelper } from "../../libraries/RouterHelper.sol";
import { StorageLibrary, MultiswapRouterFacetStorage } from "../../libraries/StorageLibrary.sol";
import { TransientStorageLibrary } from "../../libraries/TransientStorageLibrary.sol";
import { E18, UNISWAP_V3_MASK, ADDRESS_MASK, PERCENTAGE_MASK } from "../../libraries/Constants.sol";

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

import { IMultiswapRouterFacet } from "./interfaces/IMultiswapRouterFacet.sol";

/// @title MultiswapRouterFacet
/// @notice A facet for executing multi-path swaps across Uniswap V2 and V3 pools in a diamond-like proxy contract.
/// @dev Supports complex swaps with multiple pools, token wrapping, and fee payments, integrating with Uniswap V2/V3 protocols.
///      This facet is part of the diamond proxy pattern and provides functionality for multi-path token swaps
///      using Uniswap V2 and V3 protocols. It integrates with the EntryPoint contract to route calls appropriately.
contract MultiswapRouterFacet is IMultiswapRouterFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of this contract.
    ///      Immutable, set during construction.
    address private immutable _self;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the MultiswapRouterFacet with the Wrapped Native token address.
    /// @dev Sets the immutable `_self` address for callbacks.
    constructor() {
        _self = address(this);
    }

    // =========================
    // main logic
    // =========================

    /// @inheritdoc IMultiswapRouterFacet
    function multiswap(IMultiswapRouterFacet.MultiswapCalldata calldata data)
        external
        returns (bytes32[] memory tokensAndAmountsOut)
    {
        uint256 length = data.tokensIn.length;
        Utils.expectNotZero({ value: length });
        Utils.expectEqual({ left: length, right: data.pairs.length });

        uint256 tokensOutLength = data.tokensOut.length;
        Utils.expectNotZero({ value: tokensOutLength });
        Utils.expectEqual({ left: tokensOutLength, right: data.minAmountsOut.length });
        Utils.checkUnique({ addresses: data.tokensOut });

        bytes32[] memory tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        assembly ("memory-safe") {
            tokensAndAmountsOut := mload(64)
            mstore(64, add(tokensAndAmountsOut, 32))
        }

        uint256 tokenInIndexCache;
        for (uint256 i; i < length;) {
            bytes32 encodedTokenIn = data.tokensIn[i];
            address tokenIn = Utils.bytes32ToAddress({ encodedValue: encodedTokenIn });
            uint256 tokenInIndex = Utils.getHighOrder96Bits({ encodedValue: encodedTokenIn });
            Utils.expectNotZero({ value: tokenInIndex });
            Utils.compareAmounts({ greaterValue: tokenInIndex, lowerValue: tokenInIndexCache });
            uint256 amountIn;
            if (tokenInIndex != tokenInIndexCache) {
                tokenInIndexCache = tokenInIndex;
                amountIn = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: tokenIn });
            } else {
                amountIn = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmountsOut, token: tokenIn });
            }

            Utils.expectNotZero({ value: amountIn });

            _multiswap(data.pairs[i], tokensAndAmountsOut, tokenIn, amountIn);

            unchecked {
                ++i;
            }
        }

        _checkMinAmountsOut(tokensOutLength, tokensAndAmountsOut, tokensAndAmounts, data.tokensOut, data.minAmountsOut);
    }

    /// @inheritdoc IMultiswapRouterFacet
    function multiswap2(IMultiswapRouterFacet.Multiswap2Calldata calldata data)
        external
        returns (bytes32[] memory tokensAndAmountsOut)
    {
        uint256 length = data.pairs.length;
        Utils.expectNotZero({ value: length });

        Utils.expectEqual({ left: length, right: data.amountInPercentages.length });

        uint256 tokensOutLength = data.tokensOut.length;
        Utils.expectNotZero({ value: tokensOutLength });
        Utils.expectEqual({ left: tokensOutLength, right: data.minAmountsOut.length });
        Utils.checkUnique({ addresses: data.tokensOut });

        bytes32[] memory tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        assembly ("memory-safe") {
            tokensAndAmountsOut := mload(64)
            mstore(64, add(tokensAndAmountsOut, 32))
        }

        unchecked {
            uint256 lastIndex = length - 1;

            address tokenIn = data.tokenIn;
            uint256 fullAmount =
                Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: tokenIn });
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

                Utils.addElementToArrayOrAddAmount({
                    tokensAndAmounts: tokensAndAmountsOut,
                    element: Utils.encodeTokenAndAmount({ token: tokenOut, amount: amountOut })
                });
            }
        }

        _checkMinAmountsOut(tokensOutLength, tokensAndAmountsOut, tokensAndAmounts, data.tokensOut, data.minAmountsOut);
    }

    /// @inheritdoc IMultiswapRouterFacet
    function multiswapReverse(IMultiswapRouterFacet.MultiswapReverseCalldata calldata data)
        external
        returns (bytes32[] memory tokensAndAmountsOut)
    {
        uint256 length = data.tokensOut.length;
        Utils.expectNotZero({ value: length });
        Utils.expectEqual({ left: length, right: data.pairs.length });
        Utils.expectEqual({ left: length, right: data.amountsOut.length });

        uint256 tokensInLength = data.tokensIn.length;
        Utils.expectNotZero({ value: tokensInLength });
        Utils.checkUnique({ addresses: data.tokensIn });

        bytes32[] memory tokensAndAmounts = Utils.decodeTokensAndAmountsArray();
        Utils.expectEqual({ left: tokensInLength, right: tokensAndAmounts.length });
        uint256[] memory maxAmountsIn = new uint256[](tokensInLength);

        for (uint256 i; i < tokensInLength; ++i) {
            maxAmountsIn[i] =
                Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: data.tokensIn[i] });
        }
        Utils.expectEqual({ left: tokensAndAmounts.length, right: 0 });

        assembly ("memory-safe") {
            tokensAndAmountsOut := mload(64)
            mstore(64, add(tokensAndAmountsOut, 32))
        }

        MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();

        for (uint256 i; i < length;) {
            address tokenOut = data.tokensOut[i];
            uint256 amountOut = data.amountsOut[i];
            Utils.expectNotZero({ value: amountOut });

            _multiswapReverse(tokensAndAmountsOut, data.pairs[i], amountOut, tokenOut);

            address tokenIn;
            uint256 amountIn;
            {
                bytes32 tokenInAndAmountIn = s.tokenAndAmount;
                tokenIn = Utils.bytes32ToAddress({ encodedValue: tokenInAndAmountIn });
                amountIn = Utils.getHighOrder96Bits({ encodedValue: tokenInAndAmountIn });
            }
            for (uint256 j; j < tokensInLength;) {
                if (tokenIn == data.tokensIn[j]) {
                    (uint256 maxAmountIn, uint256 currentAmountIn) =
                        Utils.decodeTwoAmounts({ encodedValue: maxAmountsIn[j] });

                    unchecked {
                        maxAmountsIn[j] = Utils.encodeTwoAmounts({
                            lowerBitsAmount: maxAmountIn,
                            upperBitsAmount: currentAmountIn + amountIn
                        });
                    }
                    break;
                }
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        s.tokenAndAmount = 0;

        address sender = TransientStorageLibrary.getSenderAddress();
        for (uint256 i; i < tokensInLength;) {
            address tokenIn = data.tokensIn[i];
            (uint256 maxAmountIn, uint256 amountIn) = Utils.decodeTwoAmounts({ encodedValue: maxAmountsIn[i] });

            uint256 diff = Utils.compareAmountsWithDifference({ greaterValue: maxAmountIn, lowerValue: amountIn });

            if (diff > 0) {
                TransferHelper.safeTransfer({ token: tokenIn, to: sender, value: diff });
            }

            unchecked {
                ++i;
            }
        }

        _takeFee(tokensAndAmountsOut);
    }

    /// @notice Handles swap callbacks from Uniswap V2 and V3 pools
    /// @dev Validates the caller against the cached pool address, processes swap deltas, and transfers tokens to the pool.
    ///      Reverts with `MultiswapRouterFacet_SenderMustBePool` if the caller
    ///      is invalid or `MultiswapRouterFacet_FailedV3Swap` if the swap has no liquidity.
    ///      This function is called by Uniswap pools during swap operations.
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
                // IMultiswapRouterFacet.MultiswapRouterFacet_SenderMustBePool()
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
                revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap();
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
                    revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap();
                }

                amountOut = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
            }

            if (pathLength == 0) {
                TransferHelper.safeTransfer({ token: tokenOut, to: msg.sender, value: amountOut });
                s.tokenAndAmount = Utils.encodeTokenAndAmount({ token: tokenOut, amount: amountOut });
            } else {
                unchecked {
                    bytes32 pair = path[pathLength - 1];
                    bool uni3;

                    assembly ("memory-safe") {
                        uni3 := and(pair, UNISWAP_V3_MASK)
                    }

                    if (uni3) {
                        RouterHelper.swapUniV3ExactOut({
                            callbackAddress: _self,
                            amountOut: amountOut,
                            tokenOut: tokenOut,
                            _pool: pair,
                            destination: msg.sender,
                            path: path
                        });
                    } else {
                        RouterHelper.swapUniV2ExactOut({
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
        Utils.expectNotZero({ value: amountIn });

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
                    (amountIn, tokenIn) = RouterHelper.swapUniV3ExactIn_legacy({
                        callbackAddress: _self,
                        amountIn: amountIn,
                        tokenIn: tokenIn,
                        _pool: pair,
                        _destination: uni3Next ? addressThisBytes32 : destination,
                        destinationIsAddressThis: uni3Next
                    });
                } else {
                    (amountIn, tokenIn) = RouterHelper.swapUniV2ExactIn_legacy({
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

    /// @dev Internal function to execute a sequence of swaps.
    /// @dev Iterates over encoded pool pairs, performs swaps, and stores the resulting tokens and amounts.
    /// @param pairs Array of encoded pool data (protocol version, address, fee, percentage).
    /// @param tokensAndAmountsOut Output array to accumulate final tokens and amounts.
    /// @param tokenIn Initial input token.
    /// @param fullAmountIn Amount of input token to be swapped.
    function _multiswap(
        bytes32[] calldata pairs,
        bytes32[] memory tokensAndAmountsOut,
        address tokenIn,
        uint256 fullAmountIn
    )
        internal
    {
        uint256 length = pairs.length;
        if (length > 0) {
            uint256 remainingAmount = fullAmountIn;
            uint256 lastIndex;
            unchecked {
                lastIndex = length - 1;
            }
            for (uint256 i; i < length;) {
                bytes32 pair = pairs[i];
                bool uni3;
                uint256 percentage;
                IUniswapPool pool;

                assembly ("memory-safe") {
                    uni3 := and(pair, UNISWAP_V3_MASK)
                    pool := and(pair, ADDRESS_MASK)
                    percentage := and(shr(192, pair), PERCENTAGE_MASK)
                }
                uint256 amountIn;
                if (i == lastIndex) {
                    amountIn = remainingAmount;
                } else {
                    amountIn = fullAmountIn * percentage / E18;
                    remainingAmount -= amountIn;
                }

                if (address(pool) > address(0)) {
                    if (uni3) {
                        Utils.addElementToArrayOrAddAmount({
                            tokensAndAmounts: tokensAndAmountsOut,
                            element: RouterHelper.swapUniV3ExactIn({
                                callbackAddress: _self,
                                amountIn: amountIn,
                                tokenIn: tokenIn,
                                pool: pool
                            })
                        });
                    } else {
                        TransferHelper.safeTransfer({ token: tokenIn, to: address(pool), value: amountIn });
                        Utils.addElementToArrayOrAddAmount({
                            tokensAndAmounts: tokensAndAmountsOut,
                            element: RouterHelper.swapUniV2ExactIn({ _pair: pair, tokenIn: tokenIn })
                        });
                    }
                } else {
                    Utils.addElementToArrayOrAddAmount({
                        tokensAndAmounts: tokensAndAmountsOut,
                        element: Utils.encodeTokenAndAmount({ token: tokenIn, amount: amountIn })
                    });
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            Utils.addElementToArrayOrAddAmount({
                tokensAndAmounts: tokensAndAmountsOut,
                element: Utils.encodeTokenAndAmount({ token: tokenIn, amount: fullAmountIn })
            });
        }
    }

    /// @dev Internal function to perform reverse swaps to fulfill an exact output amount.
    /// @dev Starts from last pool and works backward to compute required input. Supports V2 and V3.
    /// @param tokensAndAmountsOut Output array to accumulate final token and amount used.
    /// @param pairs Array of encoded pool data (protocol version, address, fee).
    /// @param amountOut The desired amount of final output token.
    /// @param tokenOut The address of the output token.
    function _multiswapReverse(
        bytes32[] memory tokensAndAmountsOut,
        bytes32[] calldata pairs,
        uint256 amountOut,
        address tokenOut
    )
        internal
    {
        uint256 length = pairs.length;
        if (length > 0) {
            bytes32 pair;
            unchecked {
                pair = pairs[length - 1];
            }

            bool uni3;
            assembly ("memory-safe") {
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            uint256 balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });

            if (uni3) {
                RouterHelper.swapUniV3ExactOut({
                    callbackAddress: _self,
                    amountOut: amountOut,
                    tokenOut: tokenOut,
                    _pool: pair,
                    destination: address(this),
                    path: pairs
                });
            } else {
                RouterHelper.swapUniV2ExactOut({
                    callbackAddress: _self,
                    _pair: pair,
                    tokenOut: tokenOut,
                    destination: address(this),
                    amountOut: amountOut,
                    path: pairs
                });
            }
            amountOut = Utils.compareAmountsWithDifference({
                greaterValue: TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }),
                lowerValue: balanceOutBeforeSwap
            });
        } else {
            StorageLibrary.getMultiswapRouterFacetStorage().tokenAndAmount =
                Utils.encodeTokenAndAmount({ token: tokenOut, amount: amountOut });
        }

        Utils.addElementToArrayOrAddAmount({
            tokensAndAmounts: tokensAndAmountsOut,
            element: Utils.encodeTokenAndAmount({ token: tokenOut, amount: amountOut })
        });
    }

    /// @dev Internal function to check if the output amounts are greater than or equal to the minimum amounts.
    function _checkMinAmountsOut(
        uint256 tokensOutLength,
        bytes32[] memory tokensAndAmountsOut,
        bytes32[] memory tokensAndAmounts,
        address[] calldata tokensOut,
        uint256[] calldata minAmountsOut
    )
        internal
    {
        Utils.expectEqual({ left: tokensOutLength, right: tokensAndAmountsOut.length });
        Utils.expectEqual({ left: tokensAndAmounts.length, right: 0 });

        for (uint256 i; i < tokensOutLength;) {
            bytes32 tokenOutAndAmountOut = tokensAndAmountsOut[i];
            address tokenOut = Utils.bytes32ToAddress({ encodedValue: tokenOutAndAmountOut });
            uint256 amountOut = Utils.getHighOrder96Bits({ encodedValue: tokenOutAndAmountOut });
            for (uint256 j; j < tokensOutLength;) {
                if (tokenOut == tokensOut[j]) {
                    Utils.compareAmounts({ greaterValue: amountOut, lowerValue: minAmountsOut[j] });
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        _takeFee(tokensAndAmountsOut);
    }

    /// @dev Internal function to take fee if any
    function _takeFee(bytes32[] memory tokensAndAmounts) internal {
        (address feeToken, uint256 feeAmount) = TransientStorageLibrary.getFeeTokenAndAmount();
        if (feeToken > address(0)) {
            uint256 amount = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: feeToken });
            Utils.expectNotZero({ value: amount });
            uint256 diff = Utils.compareAmountsWithDifference({ greaterValue: amount, lowerValue: feeAmount });

            TransferHelper.safeTransfer({ token: feeToken, to: tx.origin, value: feeAmount });
            if (diff > 0) {
                Utils.addElementToArrayOrAddAmount({
                    tokensAndAmounts: tokensAndAmounts,
                    element: Utils.encodeTokenAndAmount({ token: feeToken, amount: diff })
                });
            }
        }
    }
}
