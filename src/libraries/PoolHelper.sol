// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { E6, E18 } from "./Constants.sol";

import { IUniswapPool } from "../facets/multiswapRouterFacet/interfaces/IUniswapPool.sol";

/// @title PoolHelper
library PoolHelper {
    // =========================
    // helper methods
    // =========================

    /// @dev check if tokenIn is token0 or token1 and return tokenOut
    function validateTokenInPair(IUniswapPool pool, address token) internal view returns (bool, address) {
        address token0 = pool.token0();
        // if token0 in the pair is tokenIn -> tokenOut == token1, otherwise tokenOut == token0
        if (token0 == token) {
            return (true, pool.token1());
        } else {
            return (false, token0);
        }
    }

    /// @dev return reserve of tokenIn and tokenOut in UniswapV2 pair
    function getReserves(
        bool tokenInIsToken0,
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

        (reserveInput, reserveOutput) = tokenInIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // =========================
    // V2 swaps
    // =========================

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

    function _f(uint256 x0, uint256 y) private pure returns (uint256) {
        unchecked {
            return x0 * (y * y / E18 * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18) * y / E18;
        }
    }

    function _d(uint256 x0, uint256 y) private pure returns (uint256) {
        unchecked {
            return 3 * x0 * (y * y / E18) / E18 + (x0 * x0 / E18 * x0 / E18);
        }
    }

    function _k(uint256 x, uint256 y, uint256 decimals0, uint256 decimals1) private pure returns (uint256) {
        unchecked {
            uint256 _x = x * E18 / decimals0;
            uint256 _y = y * E18 / decimals1;
            uint256 _a = (_x * _y) / E18;
            uint256 _b = ((_x * _x) / E18 + (_y * _y) / E18);
            return _a * _b / E18; // x3y+y3x >= k
        }
    }

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
