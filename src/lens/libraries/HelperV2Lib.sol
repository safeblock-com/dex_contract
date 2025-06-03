// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";
import { PoolHelper } from "../../facets/libraries/PoolHelper.sol";

import { E18, E6 } from "../../libraries/Constants.sol";

library HelperV2Lib {
    error UniswapV2_InsufficientInputAmount();
    error UniswapV2_InsufficientOutputAmount();

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

        unchecked {
            uint256 amountInWithFee = amountIn * (E6 - feeE6);
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = reserveIn * E6 + amountInWithFee;
            amountOut = numerator / denominator;
        }
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

        unchecked {
            amountIn -= amountIn * feeE6 / E6; // remove fee from amount received

            uint256 decimalsIn = 10 ** IERC20(tokenIn).decimals();
            uint256 decimalsOut = 10 ** IERC20(tokenOut).decimals();

            uint256 xy = _k(reserveIn, reserveOut, decimalsIn, decimalsOut);

            reserveIn = reserveIn * E18 / decimalsIn;
            reserveOut = reserveOut * E18 / decimalsOut;

            amountIn = amountIn * E18 / decimalsIn;

            uint256 y = reserveOut - _get_y(amountIn + reserveIn, xy, reserveOut);

            return y * decimalsOut / E18;
        }
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
            return type(uint256).max;
        }

        if (amountOut > reserveOut) {
            return type(uint256).max;
        }

        unchecked {
            uint256 numerator = reserveIn * amountOut * E6;
            uint256 denominator = (reserveOut - amountOut) * (E6 - feeE6);
            amountIn = (numerator / denominator) + 1;
        }
    }

    function stableAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE6
    )
        public
        view
        returns (uint256 amountIn)
    {
        if (amountOut == 0) {
            revert UniswapV2_InsufficientOutputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            return type(uint256).max;
        }

        if (amountOut > reserveOut) {
            return type(uint256).max;
        }

        unchecked {
            uint256 decimalsIn = 10 ** IERC20(tokenIn).decimals();
            uint256 decimalsOut = 10 ** IERC20(tokenOut).decimals();

            uint256 xy = _k(reserveIn, reserveOut, decimalsIn, decimalsOut);

            reserveIn = (reserveIn * E18) / decimalsIn;
            reserveOut = (reserveOut * E18) / decimalsOut;

            amountOut = amountOut * E18 / decimalsOut;

            uint256 x0 = _get_x(amountOut, xy, reserveIn, reserveOut, decimalsIn, decimalsOut);

            amountIn = (x0 - reserveIn) * E6 / (E6 - feeE6);

            return amountIn * decimalsIn / E18;
        }
    }

    // ===========================
    // helpers
    // ===========================

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x0 * (y * y / E18 * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18) * y / E18;
        }
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        unchecked {
            return 3 * x0 * (y * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18);
        }
    }

    function _k(uint256 x, uint256 y, uint256 decimals0, uint256 decimals1) internal pure returns (uint256) {
        unchecked {
            uint256 _x = x * E18 / decimals0;
            uint256 _y = y * E18 / decimals1;
            uint256 _a = (_x * _y) / E18;
            uint256 _b = ((_x * _x) / E18 + (_y * _y) / E18);
            return _a * _b / E18; // x3y+y3x >= k
        }
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
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

    function _get_x(
        uint256 amountOut,
        uint256 xy,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 decimalsIn,
        uint256 decimalsOut
    )
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 y = reserveOut - amountOut;
            uint256 x0 = reserveIn;
            for (uint256 i; i < 255; i++) {
                uint256 k = _f(x0, y);
                if (k < xy) {
                    uint256 dx = ((xy - k) * E18) / _d(x0, y);
                    if (dx == 0) {
                        if (k == xy) {
                            return x0;
                        }
                        if (_k(x0 + 1, y, decimalsIn, decimalsOut) > xy) {
                            return x0 + 1;
                        }
                        dx = 1;
                    }
                    x0 = x0 + dx;
                } else {
                    uint256 dx = ((k - xy) * E18) / _d(x0, y);
                    if (dx == 0) {
                        if (k == xy || _f(x0 - 1, y) < xy) {
                            return x0;
                        }
                        dx = 1;
                    }
                    x0 = x0 - dx;
                }
            }

            return type(uint256).max;
        }
    }
}
