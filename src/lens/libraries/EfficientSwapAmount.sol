// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { IUniswapPool } from "../../facets/multiswapRouterFacet/interfaces/IUniswapPool.sol";

import { HelperV2Lib } from "./HelperV2Lib.sol";
import { HelperV3Lib, Slot0, SwapCache, SwapState, FeeAndTickSpacing, TickMath, E18 } from "./HelperV3Lib.sol";

import { FullMath } from "./uni3Libs/FullMath.sol";

import { PoolHelper } from "../../libraries/PoolHelper.sol";

library EfficientSwapAmount {
    // =========================
    // errors
    // =========================

    /// @notice Throws if the target price is already reached
    error EfficientSwapAmount_TargetPriceIsAlreadyReached();

    // =========================
    // internal methods
    // =========================

    function getSpotPrice(
        bool uni3,
        bool zeroForOne,
        uint160 sqrtPriceX96,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256)
    {
        if (uni3) {
            return HelperV3Lib.calculatePrice({ sqrtPriceX96: sqrtPriceX96, zeroForOne: zeroForOne });
        } else {
            if (reserveIn == 0 || reserveOut == 0) {
                return 0;
            }
            return FullMath.mulDiv(reserveOut, E18, reserveIn);
        }
    }

    function efficientV2Amounts2(
        bool isSolidly,
        IUniswapPool pair,
        address tokenIn,
        uint256 targetPrice,
        uint256 feeE6
    )
        internal
        view
        returns (uint256 amountIn)
    {
        address tokenOut;
        uint256 reserveInput;
        uint256 reserveOutput;
        bool stableSwap;

        {
            uint256 currentPrice;
            bool tokenInIsToken0;
            (tokenInIsToken0, tokenOut) = PoolHelper.validateTokenInPair({ pool: pair, token: tokenIn });
            (reserveInput, reserveOutput, stableSwap) =
                PoolHelper.getReserves({ pair: pair, tokenInIsToken0: tokenInIsToken0, isSolidly: isSolidly });

            currentPrice = getSpotPrice({
                uni3: false,
                zeroForOne: tokenInIsToken0,
                sqrtPriceX96: 0,
                reserveIn: reserveInput,
                reserveOut: reserveOutput
            });

            if (currentPrice == 0) {
                return 0;
            }
        }

        uint256 amountOut;
        uint256 tolerance = targetPrice + targetPrice * 1e16 / E18;

        unchecked {
            uint256 low = 1;
            uint256 high = reserveInput * 10;

            while (low <= high) {
                amountIn = (low + high) >> 1;

                if (amountIn == 0) {
                    return 0;
                }

                if (stableSwap) {
                    amountOut = HelperV2Lib.stableAmountOut({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        amountIn: amountIn,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: feeE6
                    });
                } else {
                    amountOut = HelperV2Lib.volatileAmountOut({
                        amountIn: amountIn,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: feeE6
                    });
                }

                uint256 execPrice = amountOut * E18 / amountIn;

                if (execPrice <= tolerance && execPrice >= targetPrice) {
                    break;
                }

                if (execPrice > tolerance) {
                    low = amountIn;
                } else {
                    high = amountIn - 1;
                }
            }
        }
    }

    function efficientV3Amounts2(
        IUniswapPool pool,
        address tokenIn,
        uint256 targetPrice
    )
        internal
        view
        returns (uint256 amountIn)
    {
        (bool zeroForOne,) = PoolHelper.validateTokenInPair({ pool: pool, token: tokenIn });
        Slot0 memory slot0Start;
        SwapCache memory cache;
        SwapState memory state;
        FeeAndTickSpacing memory feeAndTickSpacing;

        HelperV3Lib.getDataForSimulate(pool, slot0Start, cache, state, feeAndTickSpacing, 0);
        slot0Start.targetPrice = targetPrice;

        uint256 low = 1;
        uint256 high = IERC20(tokenIn).balanceOf({ account: address(pool) }) * 100;

        uint256 amountOut;
        uint256 tolerance = targetPrice + targetPrice * 1e14 / E18;

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

            if (execPrice <= tolerance && execPrice >= targetPrice) {
                break;
            }

            if (execPrice > tolerance) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
    }
}
