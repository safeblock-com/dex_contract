// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

import { HelperLib } from "./HelperLib.sol";
import { HelperV3Lib, Slot0, SwapCache, SwapState, FeeAndTickSpacing, TickMath, E18 } from "./HelperV3Lib.sol";

import { FullMath } from "./uni3Libs/FullMath.sol";

import { PoolHelper } from "../../facets/libraries/PoolHelper.sol";

library EfficientSwapAmount {
    // =========================
    // errors
    // =========================

    /// @notice Throws if the target price is already reached
    error EfficientSwapAmount_TargetPriceIsAlreadyReached();

    // =========================
    // internal methods
    // =========================

    /// @notice Computes the input amount needed to reach a target price
    /// @param pair The pair contract address
    /// @param tokenIn The address of the token to swap
    /// @param feeE6 The fee to be applied to the swap
    /// @return amountIn The amount of input token to swap
    /// @return amountOut The amount of output token to swap
    function efficientV2Amounts(
        IUniswapPool pair,
        address tokenIn,
        uint256 targetPriceImpact,
        uint256 feeE6
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        (bool tokenInIsToken0,) = PoolHelper.validateTokenInPair({ pool: pair, token: tokenIn });
        (uint256 reserveInput, uint256 reserveOutput) =
            PoolHelper.getReserves({ pair: pair, tokenInIsToken0: tokenInIsToken0 });

        unchecked {
            uint256 low = 1;
            uint256 high = reserveInput * 10;

            // Spot price: reserveOut / reserveIn
            uint256 currentPrice = reserveOutput * E18 / reserveInput;

            while (low <= high) {
                amountIn = (low + high) >> 1;

                if (amountIn == 0) {
                    return (0, 0);
                }

                // Execution price: amountOut / amountIn
                amountOut = HelperLib.getAmountOut({
                    amountIn: amountIn,
                    reserveIn: reserveInput,
                    reserveOut: reserveOutput,
                    feeE6: feeE6
                });

                uint256 execPrice = amountOut * E18 / amountIn;

                // Price impact: (currentPrice - execPrice) / currentPrice
                uint256 priceImpact = (currentPrice - execPrice) * E18 / currentPrice;

                if (priceImpact <= targetPriceImpact) {
                    break;
                } else {
                    high = amountIn - 1;
                }
            }
        }
    }

    function efficientV3Amounts(
        IUniswapPool pool,
        address tokenIn,
        uint256 targetPriceImpact
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        (bool zeroForOne,) = PoolHelper.validateTokenInPair({ pool: pool, token: tokenIn });
        Slot0 memory slot0Start;
        SwapCache memory cache;
        SwapState memory state;
        FeeAndTickSpacing memory feeAndTickSpacing;

        HelperV3Lib.getDataForSimulate(pool, slot0Start, cache, state, feeAndTickSpacing, 0);

        uint256 currentPrice =
            HelperV3Lib.calculatePrice({ sqrtPriceX96: slot0Start.sqrtPriceX96, zeroForOne: zeroForOne });

        uint256 low = 1;
        uint256 high = HelperV3Lib.calculateVirtualReserve({
            sqrtPriceX96: slot0Start.sqrtPriceX96,
            liquidity: cache.liquidityStart,
            zeroForOne: zeroForOne
        });

        while (low <= high) {
            uint256 mid = (low + high) >> 1;

            (amountIn, amountOut) = HelperV3Lib.efficientQuoteV3({
                pool: pool,
                zeroForOne: zeroForOne,
                amountSpecified: int256(mid),
                sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
                slot0Start: slot0Start,
                cache: cache,
                state: state,
                feeAndTickSpacing: feeAndTickSpacing
            });

            if (amountOut == 0 || amountIn == 0) {
                high = mid - 1;
                continue;
            }

            uint256 execPrice = FullMath.mulDiv(amountOut, E18, amountIn);

            // Price impact: (currentPrice - execPrice) / currentPrice
            uint256 priceImpact = (currentPrice - execPrice) * E18 / currentPrice;

            if (priceImpact <= targetPriceImpact) {
                break;
            } else {
                high = mid - 1;
            }
        }
    }
}
