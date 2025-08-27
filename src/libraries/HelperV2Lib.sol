// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { E6, E18 } from "./Constants.sol";

/// @title HelperV2Lib
/// @notice Utility library for calculating swap amounts in volatile and stable AMM pools.
/// @dev Supports UniswapV2-style constant product formulas and stable curve math via Newton iteration.
///      This library is used throughout the protocol to handle AMM calculations for both volatile and stable pairs.
library HelperV2Lib {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when the input amount is less than the required minimum in Uniswap V2-style pools.
    error UniswapV2_InsufficientInputAmount();

    /// @dev Thrown when the output amount is less than the required minimum in Uniswap V2-style pools.
    error UniswapV2_InsufficientOutputAmount();

    /// @dev Thrown when there's not enough liquidity in a Uniswap V2-style pool to execute the swap.
    error UniswapV2_InsufficientLiquidity();

    // ===========================
    // amountOut
    // ===========================

    /// @notice Calculates the output amount for a volatile pair (x * y = k).
    /// @dev Calculates the output amount for a volatile pair using the constant product formula.
    /// @param amountIn Input token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format (e.g., 3000 = 0.3%).
    /// @return amountOut The amount of output tokens received.
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

        amountOut = calculateVolatileAmountOut({
            amountIn: amountIn,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    /// @notice Calculates the output amount for a stable pair using curve invariant.
    /// @dev Calculates the output amount for a stable pair using the curve invariant and Newton's method.
    /// @param tokenIn Address of the input token.
    /// @param tokenOut Address of the output token.
    /// @param amountIn Input token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return amountOut The amount of output tokens received.
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

        amountOut = calculateStableAmountOut({
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

    /// @notice Calculates the required input amount for a given output in a volatile pair.
    /// @dev Calculates the required input amount for a given output in a volatile pair using the constant product formula.
    /// @param amountOut Desired output token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return amountIn The amount of input tokens required.
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

        amountIn = calculateVolatileAmountIn({
            amountOut: amountOut,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    /// @notice Calculates the required input amount for a given output in a stable pair.
    /// @dev Calculates the required input amount for a given output in a stable pair using the curve invariant and Newton's method.
    /// @param tokenIn Address of the input token.
    /// @param tokenOut Address of the output token.
    /// @param amountOut Desired output token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return amountIn The amount of input tokens required.
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

        amountIn = calculateStableAmountIn({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountOut: amountOut,
            reserveIn: reserveIn,
            reserveOut: reserveOut,
            feeE6: feeE6
        });
    }

    // ===========================
    // math
    // ===========================

    /// @notice Calculates volatile output using constant product formula.
    /// @dev Calculates volatile output using the constant product formula: (amountIn * reserveOut) / (reserveIn + amountIn).
    /// @param amountIn Input token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return The amount of tokens to be received.
    function calculateVolatileAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 amountInWithFee = amountIn * (E6 - feeE6);
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = reserveIn * E6 + amountInWithFee;
            return numerator / denominator;
        }
    }

    /// @notice Calculates stable output using iterative solving method.
    /// @dev Calculates stable output using the curve invariant and Newton's method for solving.
    /// @param tokenIn Address of the input token.
    /// @param tokenOut Address of the output token.
    /// @param amountIn Input token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return The amount of tokens to be received.
    function calculateStableAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        view
        returns (uint256)
    {
        unchecked {
            amountIn -= amountIn * feeE6 / E6; // remove fee from amount received

            uint256 decimalsIn = 10 ** IERC20(tokenIn).decimals();
            uint256 decimalsOut = 10 ** IERC20(tokenOut).decimals();

            if (reserveIn < decimalsIn || reserveOut < decimalsOut) {
                return 0;
            }

            uint256 xy = _k(reserveIn, reserveOut, decimalsIn, decimalsOut);

            reserveIn = reserveIn * E18 / decimalsIn;
            reserveOut = reserveOut * E18 / decimalsOut;

            amountIn = amountIn * E18 / decimalsIn;

            uint256 y = reserveOut - _get_y(amountIn + reserveIn, xy, reserveOut);

            return y * decimalsOut / E18;
        }
    }

    /// @notice Calculates volatile input required using constant product formula.
    /// @dev Calculates volatile input required using the constant product formula: (reserveIn * amountOut * E6) / ((reserveOut - amountOut) * (E6 - feeE6)).
    /// @param amountOut Desired output token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return The amount of tokens to send in.
    function calculateVolatileAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 numerator = reserveIn * amountOut * E6;
            uint256 denominator = (reserveOut - amountOut) * (E6 - feeE6);
            return (numerator / denominator) + 1;
        }
    }

    /// @notice Calculates stable input required using iterative solver.
    /// @dev Calculates stable input required using the curve invariant and Newton's method for solving.
    /// @param tokenIn Address of the input token.
    /// @param tokenOut Address of the output token.
    /// @param amountOut Desired output token amount.
    /// @param reserveIn Reserve of the input token.
    /// @param reserveOut Reserve of the output token.
    /// @param feeE6 Fee in E6 format.
    /// @return The amount of tokens to send in.
    function calculateStableAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        internal
        view
        returns (uint256)
    {
        unchecked {
            uint256 decimalsIn = 10 ** IERC20(tokenIn).decimals();
            uint256 decimalsOut = 10 ** IERC20(tokenOut).decimals();

            if (reserveIn < decimalsIn || reserveOut < decimalsOut) {
                return type(uint256).max;
            }

            uint256 reserveIn18 = reserveIn * E18 / decimalsIn;
            uint256 reserveOut18 = reserveOut * E18 / decimalsOut;
            uint256 amountOut18 = amountOut * E18 / decimalsOut;

            uint256 xy = _k(reserveIn, reserveOut, decimalsIn, decimalsOut);

            uint256 x0 = _get_x(amountOut18, xy, reserveIn18, reserveOut18);

            uint256 net18 = x0 - reserveIn18;

            uint256 gross18 = net18 * E6 / (E6 - feeE6);

            return gross18 * decimalsIn / E18 + 1;
        }
    }

    // ===========================
    // private helpers
    // ===========================

    /// @dev Stable invariant function f(x, y) = x * y³ + x³ * y
    /// @param x0 The x value for the function.
    /// @param y The y value for the function.
    /// @return The result of the invariant function.
    function _f(uint256 x0, uint256 y) private pure returns (uint256) {
        unchecked {
            /// forge-lint: disable-next-line(divide-before-multiply)
            return x0 * (y * y / E18 * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18) * y / E18;
        }
    }

    /// @dev Derivative of the invariant function f with respect to y.
    /// @param x0 The x value for the function.
    /// @param y The y value for the function.
    /// @return The result of the derivative function.
    function _d(uint256 x0, uint256 y) private pure returns (uint256) {
        unchecked {
            return 3 * x0 * (y * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18);
        }
    }

    /// @dev Computes the invariant constant k based on current reserves and token decimals.
    /// @param x The reserve of token x.
    /// @param y The reserve of token y.
    /// @param decimals0 The decimals of token x.
    /// @param decimals1 The decimals of token y.
    /// @return The computed invariant constant k.
    function _k(uint256 x, uint256 y, uint256 decimals0, uint256 decimals1) private pure returns (uint256) {
        unchecked {
            uint256 _x = x * E18 / decimals0;
            uint256 _y = y * E18 / decimals1;
            uint256 _a = (_x * _y) / E18;
            uint256 _b = ((_x * _x) / E18 + (_y * _y) / E18);
            return _a * _b / E18; // x3y+y3x >= k
        }
    }

    /// @dev Iteratively solves for y using Newton's method.
    /// @param x0 The x value for the function.
    /// @param xy The invariant constant k.
    /// @param y The initial y value.
    /// @return The solved y value.
    function _get_y(uint256 x0, uint256 xy, uint256 y) private pure returns (uint256) {
        unchecked {
            for (uint256 i; i < 255; ++i) {
                uint256 y_prev = y;
                uint256 k = _f(x0, y);
                if (k < xy) {
                    uint256 dy = (xy - k) * E18 / _d(x0, y);
                    y = y + dy;
                } else {
                    uint256 dy = (k - xy) * E18 / _d(x0, y);
                    y = y - dy;
                }
                if (y > y_prev) {
                    if (y - y_prev <= 1) {
                        return y;
                    }
                } else {
                    if (y_prev - y <= 1) {
                        return y;
                    }
                }
            }
            return y;
        }
    }

    /// @dev Iteratively solves for x given output amount using Newton's method.
    /// @param amountOut The output amount.
    /// @param xy The invariant constant k.
    /// @param reserveIn18 The reserve of input token in 18 decimals.
    /// @param reserveOut18 The reserve of output token in 18 decimals.
    /// @return The solved x value.
    function _get_x(
        uint256 amountOut,
        uint256 xy,
        uint256 reserveIn18,
        uint256 reserveOut18
    )
        private
        pure
        returns (uint256)
    {
        uint256 y = reserveOut18 - amountOut;
        uint256 x = reserveIn18;

        for (uint256 i = 0; i < 255; ++i) {
            uint256 k = _f(x, y);
            uint256 d = _d(x, y);
            if (k < xy) {
                uint256 dx = ((xy - k) * E18) / d;
                x = dx == 0 ? x + 1 : x + dx;
            } else {
                uint256 dx = ((k - xy) * E18) / d;
                x = dx == 0 ? x - 1 : x - dx;
            }
            uint256 newK = _f(x, y);
            if (newK > xy) {
                if (newK - xy <= 1) break;
            } else {
                if (xy - newK <= 1) break;
            }
        }
        return x;
    }
}
