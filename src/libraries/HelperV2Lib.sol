// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PoolHelper } from "./PoolHelper.sol";
import { E6, E18 } from "./Constants.sol";

library HelperV2Lib {
    error UniswapV2_InsufficientInputAmount();
    error UniswapV2_InsufficientOutputAmount();
    error UniswapV2_InsufficientLiquidity();

    // ===========================
    // amountOut
    // ===========================

    function volatileAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            revert UniswapV2_InsufficientInputAmount();
        }
        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        amountOut = PoolHelper.calculateVolatileAmountOut({
            amountIn: amountIn,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    function stableAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        view
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            revert UniswapV2_InsufficientInputAmount();
        }
        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        amountOut = PoolHelper.calculateStableAmountOut({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    // ===========================
    // amountIn
    // ===========================

    function volatileAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        pure
        returns (uint256 amountIn)
    {
        if (amountOut == 0) {
            revert UniswapV2_InsufficientOutputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        if (amountOut > reserveOut) {
            revert UniswapV2_InsufficientOutputAmount();
        }

        amountIn = PoolHelper.calculateVolatileAmountIn({
            amountOut: amountOut,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    function stableAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        view
        returns (uint256 amountIn)
    {
        if (amountOut == 0) {
            revert UniswapV2_InsufficientOutputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        if (amountOut > reserveOut) {
            revert UniswapV2_InsufficientOutputAmount();
        }

        amountIn = PoolHelper.calculateStableAmountIn({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountOut: amountOut,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }
}
