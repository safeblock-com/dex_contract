// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

import { HelperLib } from "./HelperLib.sol";
import { HelperV3Lib } from "./HelperV3Lib.sol";
import { Sqrt } from "../../libraries/Sqrt.sol";

import { PoolHelper } from "../../facets/libraries/PoolHelper.sol";

library EfficientSwapAmount {
    uint256 internal constant FEE_DENOMINATOR = 1e6;
    uint256 internal constant E18 = 1e18;

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
    /// @param targetPriceSlippage The target price slippage to be reached
    /// @return amountIn The amount of input token to swap
    /// @return amountOut The amount of output token to swap
    function efficientV2Amounts(
        IUniswapPool pair,
        address tokenIn,
        uint256 feeE6,
        uint256 targetPriceSlippage
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        (bool tokenInIsToken0,) = PoolHelper.validateTokenInPair({ pool: pair, token: tokenIn });
        (uint256 reserveInput, uint256 reserveOutput) =
            PoolHelper.getReserves({ pair: pair, tokenInIsToken0: tokenInIsToken0 });

        unchecked {
            uint256 targetPrice = reserveOutput * E18 / reserveInput * (E18 - targetPriceSlippage) / E18;

            uint256 k = reserveInput * reserveOutput; // Constant product
            // Target reserveOut needed to reach targetPrice
            uint256 newReserveInSquared = (k * E18) / targetPrice; // Scale by 1e18 to handle precision
            uint256 newReserveIn = Sqrt.sqrt(newReserveInSquared);

            if (newReserveIn <= reserveInput) {
                revert EfficientSwapAmount_TargetPriceIsAlreadyReached();
            }

            uint256 deltaX = newReserveIn - reserveInput; // Amount needed before fee adjustment

            // Adjust for fee: amountIn = deltaX / (fee denominator - fee)
            amountIn = (deltaX * FEE_DENOMINATOR) / (FEE_DENOMINATOR - feeE6);
        }

        amountOut = HelperLib.getAmountOut({
            amountIn: amountIn,
            reserveIn: reserveInput,
            reserveOut: reserveOutput,
            feeE6: feeE6
        });
    }

    /// @notice Computes the input amount needed to reach a target price
    /// @param pool The pool contract address
    /// @param tokenIn The address of the token to swap
    /// @param targetPriceSlippage The target price slippage to be reached
    /// @return amountIn The amount of input token to swap
    /// @return amountOut The amount of output token to swap
    function efficientV3Amounts(
        IUniswapPool pool,
        address tokenIn,
        uint256 targetPriceSlippage
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        (uint160 sqrtPriceX96,,) = HelperV3Lib.getSlot0({ pool: pool });

        (bool zeroForOne,) = PoolHelper.validateTokenInPair({ pool: pool, token: tokenIn });

        unchecked {
            (amountIn, amountOut) = HelperV3Lib.quoteV3({
                pool: pool,
                zeroForOne: zeroForOne,
                amountSpecified: int256(uint256(type(uint112).max)),
                sqrtPriceLimitX96: uint160(
                    zeroForOne
                        ? sqrtPriceX96 * (E18 - targetPriceSlippage) / E18
                        : sqrtPriceX96 * (1e18 + targetPriceSlippage) / 1e18
                )
            });
        }
    }
}
