// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Utils } from "./Utils.sol";
import { HelperV2Lib } from "./HelperV2Lib.sol";
import { TransferHelper } from "./TransferHelper.sol";
import { TransientStorageLibrary } from "./TransientStorageLibrary.sol";
import { StorageLibrary, MultiswapRouterFacetStorage } from "./StorageLibrary.sol";
import { ADDRESS_MASK, FEE_MASK, MIN_SQRT_RATIO_PLUS_ONE, MAX_SQRT_RATIO_MINUS_ONE } from "./Constants.sol";

import { IUniswapPool } from "../interfaces/IUniswapPool.sol";
import { IMultiswapRouterFacet } from "../facets/multiswapRouterFacet/interfaces/IMultiswapRouterFacet.sol";

/// @title RouterHelper
/// @notice Internal helper library for executing Uniswap V2/V3 and Solidly swaps with support for exact-in and exact-out routing.
/// @dev Provides low-level swap execution and callback coordination within the diamond-based MultiswapRouterFacet.
///      Uses assembly for encoding/decoding pair information and storage caching for routing state.
///      This library is used throughout the protocol to handle Uniswap V2/V3 and Solidly swap operations.
library RouterHelper {
    // =========================
    // swap methods
    // =========================

    /// @notice Executes a Uniswap V3 swap with exact input tokens.
    /// @dev Caches the pool address and callback address, verifies output amount post-swap.
    /// @param callbackAddress The address to receive the swap callback.
    /// @param amountIn The amount of input tokens.
    /// @param tokenIn The input token address.
    /// @param pool The Uniswap V3 pool contract.
    /// @return tokenOutAndAmount Encoded output token and amount.
    function swapUniV3ExactIn(
        address callbackAddress,
        uint256 amountIn,
        address tokenIn,
        IUniswapPool pool
    )
        internal
        returns (bytes32 tokenOutAndAmount)
    {
        Utils.checkIntCast({ amount: amountIn });

        (bool zeroForOne, address tokenOut) = RouterHelper.validateTokenInPair({ pool: pool, token: tokenIn });

        {
            // caching the pool address and swapType in storage
            MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
            assembly ("memory-safe") {
                sstore(s.slot, pool)
            }
            // caching the callback address
            TransientStorageLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
        }

        uint256 balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });

        pool.swap({
            recipient: address(this),
            zeroForOne: zeroForOne,
            amountSpecified: int256(amountIn),
            sqrtPriceLimitX96: (zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            data: abi.encode(tokenIn)
        });

        return Utils.encodeTokenAndAmount({
            token: tokenOut,
            amount: Utils.compareAmountsWithDifference({
                greaterValue: TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }),
                lowerValue: balanceOutBeforeSwap
            })
        });
    }

    /// @notice Executes a Uniswap V3 swap with exact output tokens.
    /// @dev Caches the callback and path info for re-entrant callback execution.
    /// @param callbackAddress The address to receive the swap callback.
    /// @param amountOut Desired output amount.
    /// @param tokenOut Address of the output token.
    /// @param _pool Encoded pool identifier.
    /// @param destination Recipient address for tokens.
    /// @param path Encoded swap path.
    function swapUniV3ExactOut(
        address callbackAddress,
        uint256 amountOut,
        address tokenOut,
        bytes32 _pool,
        address destination,
        bytes32[] memory path
    )
        internal
    {
        IUniswapPool pool;
        assembly ("memory-safe") {
            pool := and(_pool, ADDRESS_MASK)
        }

        (bool zeroForOne, address tokenIn) = validateTokenInPair(pool, tokenOut);

        Utils.checkIntCast({ amount: amountOut });

        {
            // caching the pool address and swapType in storage
            MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
            assembly ("memory-safe") {
                sstore(s.slot, add(shl(168, mload(path)), add(shl(160, 2), pool)))
            }
            // caching the callback address
            TransientStorageLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
        }

        pool.swap({
            recipient: destination,
            zeroForOne: !zeroForOne,
            amountSpecified: -int256(amountOut),
            sqrtPriceLimitX96: (!zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            data: abi.encode(0, tokenIn, path)
        });
    }

    /// @notice Executes a Uniswap V2 (or Solidly) swap with exact input tokens.
    /// @dev Determines if pair is stable/volatile and selects appropriate math.
    /// @param _pair Encoded pair identifier.
    /// @param tokenIn Address of the input token.
    /// @return tokenOutAndAmount Encoded output token and amount.
    function swapUniV2ExactIn(bytes32 _pair, address tokenIn) internal returns (bytes32 tokenOutAndAmount) {
        IUniswapPool pair;
        uint256 isSolidly;
        uint256 fee;
        assembly ("memory-safe") {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(shr(160, _pair), FEE_MASK)
            isSolidly := and(shr(184, _pair), 0xff)
        }

        uint256 amountInput;
        uint256 amountOut;

        (bool zeroForOne, address tokenOut) = RouterHelper.validateTokenInPair({ pool: pair, token: tokenIn });

        // scope to avoid stack too deep errors
        {
            (uint256 reserveInput, uint256 reserveOutput, bool stableSwap) =
                getReserves({ pair: pair, zeroForOne: zeroForOne, isSolidly: isSolidly > 0 });

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = Utils.compareAmountsWithDifference(
                    TransferHelper.safeGetBalance({ token: tokenIn, account: address(pair) }), reserveInput
                );
            }

            if (stableSwap) {
                amountOut = HelperV2Lib.stableAmountOut({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountInput,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: fee
                });
            } else {
                amountOut = HelperV2Lib.volatileAmountOut({
                    amountIn: amountInput,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: fee
                });
            }
        }

        (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));

        uint256 balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });

        if (
            // first do the swap via the most common swap function selector
            // swap(uint256,uint256,address,bytes) selector
            !Utils.makeCall(
                address(pair), abi.encodeWithSelector(0x022c0d9f, amount0Out, amount1Out, address(this), bytes(""))
            )
        ) {
            if (
                // if revert - try to swap through another selector
                // swap(uint256,uint256,address) selector
                !Utils.makeCall(address(pair), abi.encodeWithSelector(0x6d9a640a, amount0Out, amount1Out, address(this)))
            ) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV2Swap();
            }
        }

        return Utils.encodeTokenAndAmount({
            token: tokenOut,
            amount: Utils.compareAmountsWithDifference({
                greaterValue: TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }),
                lowerValue: balanceOutBeforeSwap
            })
        });
    }

    /// @notice Executes a Uniswap V2 (or Solidly) swap with exact output tokens.
    /// @dev Calculates required input and caches callback+path data.
    /// @param callbackAddress The address to receive the swap callback.
    /// @param _pair Encoded pair identifier.
    /// @param tokenOut Output token address.
    /// @param destination Recipient address.
    /// @param amountOut Exact amount to receive.
    /// @param path Encoded swap path.
    function swapUniV2ExactOut(
        address callbackAddress,
        bytes32 _pair,
        address tokenOut,
        address destination,
        uint256 amountOut,
        bytes32[] memory path
    )
        internal
    {
        IUniswapPool pair;
        uint256 amountIn;
        address tokenIn;
        uint256 amount0Out;
        uint256 amount1Out;
        {
            bool zeroForOne;
            (pair, amountIn, zeroForOne, tokenIn) = _getAmountIn(_pair, tokenOut, amountOut);

            (amount0Out, amount1Out) = !zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));

            // caching the pool address and swapType in storage
            MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
            assembly ("memory-safe") {
                sstore(s.slot, add(shl(168, mload(path)), add(shl(160, 1), pair)))
            }
            // caching the callback address
            TransientStorageLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
        }

        if (
            // do the swap via the most common swap function selector
            // swap(uint256,uint256,address,bytes) selector
            !Utils.makeCall(
                address(pair),
                abi.encodeWithSelector(
                    0x022c0d9f, amount0Out, amount1Out, destination, abi.encode(amountIn, tokenIn, path)
                )
            )
        ) {
            revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV2Swap();
        }
    }

    /// @notice Legacy Uniswap V3 exact-in variant with extended destination flag.
    /// @param callbackAddress The address to receive the swap callback.
    /// @param amountIn The input amount for the swap.
    /// @param tokenIn The input token for the swap.
    /// @param _pool The encoded pool identifier (includes address and Uniswap V3 flag).
    /// @param _destination The encoded destination for the output tokens.
    /// @param destinationIsAddressThis Whether the destination is this contract.
    /// @return amountOut The output amount from the swap.
    /// @return tokenOut The output token from the swap.
    function swapUniV3ExactIn_legacy(
        address callbackAddress,
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
        (zeroForOne, tokenOut) = validateTokenInPair(pool, tokenIn);

        Utils.checkIntCast({ amount: amountIn });

        {
            // caching the pool address and swapType in storage
            MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
            assembly ("memory-safe") {
                sstore(s.slot, pool)
            }
            // caching the callback address
            TransientStorageLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
        }

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
            amountOut = Utils.compareAmountsWithDifference({
                greaterValue: TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }),
                lowerValue: balanceOutBeforeSwap
            });
        }
    }

    /// @notice Legacy Uniswap V2 exact-in variant with extended destination flag.
    /// @param _pair The encoded pair identifier (includes address, fee, and Solidly flag).
    /// @param tokenIn The input token for the swap.
    /// @param _destination The encoded destination for the output tokens.
    /// @param destinationIsAddressThis Whether the destination is this contract.
    /// @return amountOut The output amount from the swap.
    /// @return tokenOut The output token from the swap.
    function swapUniV2ExactIn_legacy(
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

        bool zeroForOne;
        (zeroForOne, tokenOut) = validateTokenInPair(pair, tokenIn);

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserveInput, uint256 reserveOutput, bool stableSwap) =
                getReserves({ pair: pair, zeroForOne: zeroForOne, isSolidly: isSolidly > 0 });

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = Utils.compareAmountsWithDifference({
                    greaterValue: TransferHelper.safeGetBalance({ token: tokenIn, account: address(pair) }),
                    lowerValue: reserveInput
                });
            }

            if (stableSwap) {
                amountOut = HelperV2Lib.stableAmountOut({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountInput,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: fee
                });
            } else {
                amountOut = HelperV2Lib.volatileAmountOut({
                    amountIn: amountInput,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: fee
                });
            }
        }

        (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));

        uint256 balanceOutBeforeSwap;
        if (destinationIsAddressThis) {
            balanceOutBeforeSwap = TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) });
        }

        if (
            // first do the swap via the most common swap function selector
            // swap(uint256,uint256,address,bytes) selector
            !Utils.makeCall(
                address(pair), abi.encodeWithSelector(0x022c0d9f, amount0Out, amount1Out, destination, bytes(""))
            )
        ) {
            if (
                // if revert - try to swap through another selector
                // swap(uint256,uint256,address) selector
                !Utils.makeCall(address(pair), abi.encodeWithSelector(0x6d9a640a, amount0Out, amount1Out, destination))
            ) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_FailedV2Swap();
            }
        }

        if (destinationIsAddressThis) {
            amountOut = Utils.compareAmountsWithDifference({
                greaterValue: TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }),
                lowerValue: balanceOutBeforeSwap
            });
        }
    }

    // =========================
    // helper methods
    // =========================

    /// @dev Validates input token and determines direction of swap.
    function validateTokenInPair(IUniswapPool pool, address token) internal view returns (bool, address) {
        address token0 = pool.token0();
        // if token0 in the pair is tokenIn -> tokenOut == token1, otherwise tokenOut == token0
        if (token0 == token) {
            return (true, pool.token1());
        } else {
            return (false, token0);
        }
    }

    /// @dev Fetches reserves and determines if pair is stable or volatile.
    function getReserves(
        bool zeroForOne,
        bool isSolidly,
        IUniswapPool pair
    )
        internal
        view
        returns (uint256 reserveInput, uint256 reserveOutput, bool stableSwap)
    {
        uint256 reserve0;
        uint256 reserve1;

        unchecked {
            if (isSolidly) {
                try pair.metadata() returns (uint256, uint256, uint256 r0, uint256 r1, bool st, address, address) {
                    reserve0 = r0;
                    reserve1 = r1;
                    stableSwap = st;
                } catch {
                    /// forge-lint: disable-next-line(unchecked-call)
                    (, bytes memory data) = address(pair).staticcall(abi.encodeWithSignature("getReserves()"));
                    uint256 feeToken0;
                    uint256 feeToken1;
                    (reserve0, reserve1, feeToken0, feeToken1) = abi.decode(data, (uint256, uint256, uint256, uint256));
                    stableSwap = pair.stableSwap();
                }
            } else {
                (reserve0, reserve1,) = pair.getReserves();
            }
        }

        (reserveInput, reserveOutput) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @dev Helper function to get the input amount for a Uniswap V2 reverse swap.
    /// @param _pair The encoded pair identifier (includes address, fee, and Solidly flag).
    /// @param tokenOut The output token for the swap.
    /// @param amountOut The exact output amount for the swap.
    /// @return pair The pair for the swap.
    /// @return amountIn The input amount for the swap.
    /// @return tokenInIsToken1 Whether the input token is token1 in the pair.
    /// @return tokenIn The input token for the swap.
    function _getAmountIn(
        bytes32 _pair,
        address tokenOut,
        uint256 amountOut
    )
        private
        view
        returns (IUniswapPool pair, uint256 amountIn, bool tokenInIsToken1, address tokenIn)
    {
        uint256 isSolidly;
        uint256 fee;
        assembly ("memory-safe") {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(shr(160, _pair), FEE_MASK)
            isSolidly := and(shr(184, _pair), 0xff)
        }

        (tokenInIsToken1, tokenIn) = validateTokenInPair(pair, tokenOut);

        (uint256 reserveInput, uint256 reserveOutput, bool stableSwap) =
            getReserves({ pair: pair, zeroForOne: !tokenInIsToken1, isSolidly: isSolidly > 0 });

        if (stableSwap) {
            amountIn = HelperV2Lib.stableAmountIn({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountOut: amountOut,
                reserveIn: reserveInput,
                reserveOut: reserveOutput,
                feeE6: fee
            });
        } else {
            amountIn = HelperV2Lib.volatileAmountIn({
                amountOut: amountOut,
                reserveIn: reserveInput,
                reserveOut: reserveOutput,
                feeE6: fee
            });
        }
    }

    // =========================
    // getFee helper
    // =========================

    function getFee(IUniswapPool pair, bool stableSwap) internal view returns (uint256 feeE6) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSignature("feeRatio()"));

        if (success) {
            feeE6 = abi.decode(data, (uint256));
        } else {
            (success, data) = address(pair).staticcall(abi.encodeWithSignature("swapFee()"));

            if (success) {
                feeE6 = abi.decode(data, (uint256)) * 100;
            } else {
                (success, data) = address(pair).staticcall(abi.encodeWithSignature("pairFee()"));

                if (success) {
                    feeE6 = abi.decode(data, (uint256)) / 1_000_000_000_000;
                } else {
                    (success, data) = address(pair).staticcall(abi.encodeWithSignature("factory()"));

                    if (success) {
                        address factory = abi.decode(data, (address));

                        (success, data) =
                            address(factory).staticcall(abi.encodeWithSignature("getFee(bool)", stableSwap));

                        if (success) {
                            feeE6 = abi.decode(data, (uint256)) * 100;
                        } else {
                            (success, data) = address(factory).staticcall(
                                abi.encodeWithSignature("getFee(address,bool)", pair, stableSwap)
                            );

                            if (success) {
                                feeE6 = abi.decode(data, (uint256)) * 100;
                            } else {
                                (success, data) =
                                    address(factory).staticcall(abi.encodeWithSignature("getFee(address)", pair));

                                if (success) {
                                    feeE6 = abi.decode(data, (uint256)) * 100;
                                } else {
                                    feeE6 = 500;
                                }
                            }
                        }
                    } else {
                        if (stableSwap) {
                            feeE6 = 300;
                        } else {
                            feeE6 = 2500;
                        }
                    }
                }
            }
        }
    }
}
