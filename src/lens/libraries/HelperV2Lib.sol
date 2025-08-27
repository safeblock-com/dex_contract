// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { HelperV2Lib as Math } from "../../libraries/HelperV2Lib.sol";

import { HelperV2Lib as External } from "../../libraries/HelperV2Lib.sol";

library HelperV2Lib {
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
            revert External.UniswapV2_InsufficientInputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            return 0;
        }

        amountOut = Math.calculateVolatileAmountOut({
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
            revert External.UniswapV2_InsufficientInputAmount();
        }

        amountOut = Math.calculateStableAmountOut({
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
            revert External.UniswapV2_InsufficientOutputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            return type(uint256).max;
        }

        if (amountOut > reserveOut) {
            return type(uint256).max;
        }

        amountIn = Math.calculateVolatileAmountIn({
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
            revert External.UniswapV2_InsufficientOutputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            return type(uint256).max;
        }

        if (amountOut > reserveOut) {
            return type(uint256).max;
        }

        amountIn = Math.calculateStableAmountIn({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountOut: amountOut,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }
}
