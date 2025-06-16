// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../facets/multiswapRouterFacet/interfaces/IUniswapPool.sol";

import { TickBitmap } from "./uni3Libs/TickBitmap.sol";
import { TickMath } from "./uni3Libs/TickMath.sol";
import { SwapMath } from "./uni3Libs/SwapMath.sol";
import { SafeCast } from "./uni3Libs/SafeCast.sol";
import { FixedPoint128 } from "./uni3Libs/FixedPoint128.sol";
import { FullMath } from "./uni3Libs/FullMath.sol";

import { E18, _2E96 } from "../../libraries/Constants.sol";

import { console2 } from "forge-std/console2.sol";

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    //
    uint256 targetPrice;
}

struct SwapCache {
    uint128 liquidityStart;
    uint256[] tickBitmaps;
    int128[] liquidityNets;
    bool[] initialized;
    uint256 index;
}

// the top level state of the swap, the results of which are recorded in storage at the end
struct SwapState {
    // the amount remaining to be swapped in/out of the input/output asset
    int256 amountSpecifiedRemaining;
    // the amount already swapped out/in of the output/input asset
    int256 amountCalculated;
    // current sqrt(price)
    uint160 sqrtPriceX96;
    // the tick associated with the current price
    int24 tick;
    // the current liquidity in range
    uint128 liquidity;
}

struct StepComputations {
    // the price at the beginning of the step
    uint160 sqrtPriceStartX96;
    // the next tick to swap to from the current tick in the swap direction
    int24 tickNext;
    // whether tickNext is initialized or not
    bool initialized;
    // sqrt(price) for the next tick (1/0)
    uint160 sqrtPriceNextX96;
    // how much is being swapped in in this step
    uint256 amountIn;
    // how much is being swapped out
    uint256 amountOut;
    // how much fee is being paid in
    uint256 feeAmount;
}

struct FeeAndTickSpacing {
    uint24 fee;
    int24 tickSpacing;
}

library HelperV3Lib {
    function getDataForSimulate(
        IUniswapPool pool,
        Slot0 memory slot0Start,
        SwapCache memory cache,
        SwapState memory state,
        FeeAndTickSpacing memory feeAndTickSpacing,
        int256 amountSpecified
    )
        internal
        view
    {
        if (slot0Start.sqrtPriceX96 == 0) {
            (uint160 sqrtPriceX96, int24 tick) = getSlot0(pool);

            slot0Start.sqrtPriceX96 = sqrtPriceX96;
            slot0Start.tick = tick;

            (uint24 fee, int24 tickSpacing, uint128 liquidity) = getFeeTickSpacingAndLiquidity(pool);

            feeAndTickSpacing.fee = fee;
            feeAndTickSpacing.tickSpacing = tickSpacing;

            cache.liquidityStart = liquidity;

            cache.liquidityNets = new int128[](128);
            cache.tickBitmaps = new uint256[](128);
            cache.initialized = new bool[](128);
        }

        state.amountSpecifiedRemaining = amountSpecified;
        state.sqrtPriceX96 = slot0Start.sqrtPriceX96;
        state.tick = slot0Start.tick;
        state.liquidity = cache.liquidityStart;
        state.amountCalculated = 0;
        cache.index = 0;
    }

    function quoteV3(
        IUniswapPool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    )
        internal
        view
        returns (uint256, uint256)
    {
        Slot0 memory slot0Start;
        SwapCache memory cache;
        bool exactInput = amountSpecified > 0;
        SwapState memory state;
        FeeAndTickSpacing memory feeAndTickSpacing;
        {
            {
                (uint160 sqrtPriceX96, int24 tick) = getSlot0(pool);

                slot0Start.sqrtPriceX96 = sqrtPriceX96;
                slot0Start.tick = tick;
            }

            (uint24 fee, int24 tickSpacing, uint128 liquidity) = getFeeTickSpacingAndLiquidity(pool);

            if (liquidity == 0 || amountSpecified == 0) {
                return (exactInput ? 0 : type(uint256).max, 0);
            }

            cache.liquidityStart = liquidity;

            feeAndTickSpacing.fee = fee;
            feeAndTickSpacing.tickSpacing = tickSpacing;

            state.amountSpecifiedRemaining = amountSpecified;
            state.sqrtPriceX96 = slot0Start.sqrtPriceX96;
            state.tick = slot0Start.tick;
            state.liquidity = liquidity;
        }

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) =
                TickBitmap.nextInitializedTickWithinOneWord(pool, state.tick, feeAndTickSpacing.tickSpacing, zeroForOne);

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                feeAndTickSpacing.fee
            );

            if (exactInput) {
                // safe because we test that amountSpecified > amountIn + feeAmount in SwapMath
                unchecked {
                    state.amountSpecifiedRemaining -= SafeCast.toInt256(step.amountIn + step.feeAmount);
                }
                state.amountCalculated -= SafeCast.toInt256(step.amountOut);
            } else {
                unchecked {
                    state.amountSpecifiedRemaining += SafeCast.toInt256(step.amountOut);
                }
                state.amountCalculated += SafeCast.toInt256(step.amountIn + step.feeAmount);
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    int128 liquidityNet = getTickLiquidityNet(pool, step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                if (state.liquidity == 0 && state.amountSpecifiedRemaining != 0) {
                    return (exactInput ? 0 : type(uint256).max, 0);
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        if (state.amountSpecifiedRemaining != 0) {
            return (exactInput ? 0 : type(uint256).max, 0);
        }

        unchecked {
            (int256 amount0, int256 amount1) = zeroForOne == exactInput
                ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
                : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

            if (amount0 == 0 || amount1 == 0) {
                return (exactInput ? 0 : type(uint256).max, 0);
            }

            return
                (amount0 > 0 ? uint256(amount0) : uint256(amount1), amount0 < 0 ? uint256(-amount0) : uint256(-amount1));
        }
    }

    function efficientQuoteV3(
        IUniswapPool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        Slot0 memory slot0Start,
        SwapCache memory cache,
        SwapState memory state,
        FeeAndTickSpacing memory feeAndTickSpacing
    )
        internal
        view
        returns (uint256, uint256)
    {
        bool exactInput = amountSpecified > 0;

        getDataForSimulate(pool, slot0Start, cache, state, feeAndTickSpacing, amountSpecified);

        if (state.liquidity == 0 || amountSpecified == 0) {
            return (exactInput ? 0 : type(uint256).max, 0);
        }

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;
            (step.tickNext, step.initialized) = TickBitmap.nextInitializedTickWithinOneWord(
                pool, state.tick, feeAndTickSpacing.tickSpacing, zeroForOne, cache
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                feeAndTickSpacing.fee
            );

            if (exactInput) {
                // safe because we test that amountSpecified > amountIn + feeAmount in SwapMath
                unchecked {
                    state.amountSpecifiedRemaining -= SafeCast.toInt256(step.amountIn + step.feeAmount);
                }
                state.amountCalculated -= SafeCast.toInt256(step.amountOut);

                if (
                    FullMath.mulDiv(
                        uint256(-state.amountCalculated), E18, uint256(amountSpecified - state.amountSpecifiedRemaining)
                    ) < slot0Start.targetPrice
                ) {
                    return (exactInput ? 0 : type(uint256).max, 0);
                }
            } else {
                unchecked {
                    state.amountSpecifiedRemaining += SafeCast.toInt256(step.amountOut);
                }
                state.amountCalculated += SafeCast.toInt256(step.amountIn + step.feeAmount);
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    int128 liquidityNet;
                    step.initialized = cache.index < cache.liquidityNets.length;
                    if (step.initialized) {
                        liquidityNet = cache.liquidityNets[cache.index];
                    }
                    if (liquidityNet == 0) {
                        liquidityNet = getTickLiquidityNet(pool, step.tickNext);

                        if (step.initialized) {
                            cache.liquidityNets[cache.index] = liquidityNet;
                        }
                    }
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                if (state.liquidity == 0 && state.amountSpecifiedRemaining != 0) {
                    return (exactInput ? 0 : type(uint256).max, 0);
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
            ++cache.index;
        }

        unchecked {
            (int256 amount0, int256 amount1) = zeroForOne == exactInput
                ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
                : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

            if (amount0 == 0 || amount1 == 0) {
                return (exactInput ? 0 : type(uint256).max, 0);
            }

            return
                (amount0 > 0 ? uint256(amount0) : uint256(amount1), amount0 < 0 ? uint256(-amount0) : uint256(-amount1));
        }
    }

    function getTickLiquidityNet(IUniswapPool pool, int24 tick) internal view returns (int128 liquidityNet) {
        (, bytes memory data) = address(pool).staticcall(abi.encodeWithSignature("ticks(int24)", tick));

        if (data.length == 320) {
            (, liquidityNet,,,,,,,,) =
                abi.decode(data, (uint128, int128, uint256, uint256, uint256, uint256, int256, uint256, uint256, bool));
        } else if (data.length > 96) {
            (, liquidityNet,,,,,,) =
                abi.decode(data, (uint128, int128, uint256, uint256, int256, uint256, uint256, bool));
        } else {
            (, liquidityNet,) = abi.decode(data, (uint128, int128, bool));
        }
    }

    function getFeeTickSpacingAndLiquidity(IUniswapPool pool)
        internal
        view
        returns (uint24 fee, int24 tickSpacing, uint128 liquidity)
    {
        assembly {
            fee := mload(0x00)
        }

        bytes memory data;

        if (fee == 0) {
            (, data) = address(pool).staticcall(abi.encodeWithSignature("fee()"));
            fee = abi.decode(data, (uint24));
        }

        (, data) = address(pool).staticcall(abi.encodeWithSignature("tickSpacing()"));
        tickSpacing = abi.decode(data, (int24));

        (, data) = address(pool).staticcall(abi.encodeWithSignature("liquidity()"));
        liquidity = abi.decode(data, (uint128));
    }

    function getSlot0(IUniswapPool pool) internal view returns (uint160 sqrtPriceX96, int24 tick) {
        (bool success, bytes memory data) = address(pool).staticcall(abi.encodeWithSignature("slot0()"));

        if (success) {
            if (data.length > 128) {
                assembly ("memory-safe") {
                    sqrtPriceX96 := mload(add(data, 32))
                    tick := mload(add(data, 64))
                }
            } else {
                uint256 fee;

                (sqrtPriceX96, tick, fee,) = abi.decode(data, (uint160, int24, uint256, uint256));
                assembly ("memory-safe") {
                    mstore(0x00, fee)
                }
            }
        } else {
            (, data) = address(pool).staticcall(abi.encodeWithSignature("globalState()"));

            if (data.length == 224) {
                uint256 fee;
                (sqrtPriceX96, tick, fee,,,) = abi.decode(data, (uint160, int24, uint16, uint8, uint16, bool));

                assembly ("memory-safe") {
                    mstore(0x00, fee)
                }
            } else {
                (sqrtPriceX96, tick,,,,) = abi.decode(data, (uint160, int24, uint16, uint8, uint16, bool));
            }
        }

        assembly ("memory-safe") {
            mstore(0x40, data)
        }
    }

    function calculatePrice(uint160 sqrtPriceX96, bool zeroForOne) internal pure returns (uint256) {
        if (zeroForOne) {
            return FullMath.mulDiv(FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, _2E96), E18, _2E96);
        } else {
            return FullMath.mulDiv(_2E96, E18, FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, _2E96));
        }
    }

    function calculateVirtualReserve(
        uint256 sqrtPriceX96,
        uint256 liquidity,
        bool zeroForOne
    )
        internal
        pure
        returns (uint256)
    {
        if (zeroForOne) {
            // reserve_token_0 = L / sqrt(P)
            return FullMath.mulDiv(uint256(liquidity), _2E96, sqrtPriceX96);
        } else {
            // reserve_token_1 = L * sqrt(P)
            return FullMath.mulDiv(uint256(liquidity), sqrtPriceX96, _2E96);
        }
    }
}
