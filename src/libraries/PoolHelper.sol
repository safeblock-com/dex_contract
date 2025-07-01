// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IErrors } from "../interfaces/IErrors.sol";

import { HelperV2Lib } from "./HelperV2Lib.sol";
import { Utils } from "./Utils.sol";
import { TransferHelper } from "./TransferHelper.sol";
import { TransientStorageFacetLibrary } from "./TransientStorageFacetLibrary.sol";
import { StorageLibrary, MultiswapRouterFacetStorage } from "./StorageLibrary.sol";
import {
    ADDRESS_MASK,
    FEE_MASK,
    E6,
    E18,
    CAST_INT_CONSTANT,
    MIN_SQRT_RATIO_PLUS_ONE,
    MAX_SQRT_RATIO_MINUS_ONE
} from "./Constants.sol";

import { IUniswapPool } from "../facets/multiswapRouterFacet/interfaces/IUniswapPool.sol";

/// @title PoolHelper
library PoolHelper {
    // =========================
    // swap methods
    // =========================

    /// @dev Executes a Uniswap V3 swap with exact input tokens.
    ///      Calls the Uniswap V3 pool's `swap` function, caches the pool address for the callback,
    ///      and verifies the output amount if the destination is this contract.
    /// @param amountIn The input amount for the swap.
    /// @param tokenIn The input token for the swap.
    /// @param _pool The encoded pool identifier (includes address and Uniswap V3 flag).
    /// @param _destination The encoded destination for the output tokens.
    /// @param destinationIsAddressThis Whether the destination is this contract.
    /// @return amountOut The output amount from the swap.
    /// @return tokenOut The output token from the swap.
    function swapUniV3ExactIn(
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
            TransientStorageFacetLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
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
            // return the exact amount of tokens as a result of the swap
            amountOut = Utils.compareAmounts(
                TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }), balanceOutBeforeSwap
            );
        }
    }

    /// @dev Executes a Uniswap V3 swap with exact output tokens.
    ///      Calls the Uniswap V3 pool's `swap` function and caches the pool address for the callback.
    /// @param amountOut The exact output amount for the swap.
    /// @param tokenOut The output token for the swap.
    /// @param _pool The encoded pool identifier (includes address and Uniswap V3 flag).
    /// @param destination The destination for the output tokens.
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
            TransientStorageFacetLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
        }

        pool.swap({
            recipient: destination,
            zeroForOne: !zeroForOne,
            amountSpecified: -int256(amountOut),
            sqrtPriceLimitX96: (!zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            data: abi.encode(0, tokenIn, path)
        });
    }

    /// @dev Executes a Uniswap V2 swap with exact input tokens.
    ///      Transfers input tokens to the pair, calculates the output amount, and calls the pair’s swap function.
    ///      Supports multiple swap function selectors and Solidly-style pairs.
    ///      Reverts with `MultiswapRouterFacet_FailedV2Swap` if the swap fails.
    /// @param _pair The encoded pair identifier (includes address, fee, and Solidly flag).
    /// @param tokenIn The input token for the swap.
    /// @param _destination The encoded destination for the output tokens.
    /// @param destinationIsAddressThis Whether the destination is this contract.
    /// @return amountOut The output amount from the swap.
    /// @return tokenOut The output token from the swap.
    function swapUniV2ExactIn(
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

        bool tokenInIsToken0;
        (tokenInIsToken0, tokenOut) = validateTokenInPair(pair, tokenIn);

        uint256 amountInput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserveInput, uint256 reserveOutput, bool stableSwap) =
                getReserves({ pair: pair, tokenInIsToken0: tokenInIsToken0, isSolidly: isSolidly > 0 });

            // get the exact number of tokens that were sent to the pair
            // underflow is impossible cause after token transfer via token contract
            // reserves in the pair not updated yet
            unchecked {
                amountInput = Utils.compareAmounts(
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

        (uint256 amount0Out, uint256 amount1Out) = tokenInIsToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

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
                revert IErrors.MultiswapRouterFacet_FailedV2Swap();
            }
        }

        if (destinationIsAddressThis) {
            // return the exact amount of tokens as a result of the swap
            amountOut = Utils.compareAmounts(
                TransferHelper.safeGetBalance({ token: tokenOut, account: address(this) }), balanceOutBeforeSwap
            );
        }
    }

    /// @dev Executes a Uniswap V2 swap with exact output tokens.
    ///      Requests output tokens from the pair and starts the callback for iterates through the pairs.
    ///      Supports Solidly-style pairs.
    ///      Reverts with `MultiswapRouterFacet_FailedV2Swap` if the swap fails.
    /// @param _pair The encoded pair identifier (includes address, fee, and Solidly flag).
    /// @param tokenOut The output token for the swap.
    /// @param amountOut The exact output amount for the swap.
    /// @param destination The destination for the output tokens.
    /// @param path The array of pool identifiers for the swap path.
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
            bool tokenInIsToken0;
            (pair, amountIn, tokenInIsToken0, tokenIn) = _getAmountIn(_pair, tokenOut, amountOut);

            (amount0Out, amount1Out) = !tokenInIsToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            // caching the pool address and swapType in storage
            MultiswapRouterFacetStorage storage s = StorageLibrary.getMultiswapRouterFacetStorage();
            assembly ("memory-safe") {
                sstore(s.slot, add(shl(168, mload(path)), add(shl(160, 1), pair)))
            }
            // caching the callback address
            TransientStorageFacetLibrary.setCallbackAddress({ callbackAddress: callbackAddress });
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
            revert IErrors.MultiswapRouterFacet_FailedV2Swap();
        }
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
            getReserves({ pair: pair, tokenInIsToken0: !tokenInIsToken1, isSolidly: isSolidly > 0 });

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
