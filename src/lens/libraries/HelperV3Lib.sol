// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

import { TickBitmap } from "./uni3Libs/TickBitmap.sol";
import { TickMath } from "./uni3Libs/TickMath.sol";
import { SwapMath } from "./uni3Libs/SwapMath.sol";
import { SafeCast } from "./uni3Libs/SafeCast.sol";
import { FixedPoint128 } from "./uni3Libs/FixedPoint128.sol";
import { FullMath } from "./uni3Libs/FullMath.sol";

import { PoolTicksCounter } from "./uni3Libs/PoolTicksCounter.sol";

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint256 feeProtocol;
}

struct SwapCache {
    // the protocol fee for the input token
    uint256 feeProtocol;
    // liquidity at the beginning of the swap
    uint128 liquidityStart;
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
                (uint160 sqrtPriceX96, int24 tick, uint256 feeProtocol) = getSlot0(pool);
                slot0Start.sqrtPriceX96 = sqrtPriceX96;
                slot0Start.tick = tick;
                slot0Start.feeProtocol = feeProtocol;

                unchecked {
                    if (zeroForOne) {
                        if (sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 || sqrtPriceLimitX96 < TickMath.MIN_SQRT_RATIO)
                        {
                            sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
                        }
                    } else {
                        if (sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 || sqrtPriceLimitX96 > TickMath.MAX_SQRT_RATIO)
                        {
                            sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
                        }
                    }
                }
            }

            (uint24 fee, int24 tickSpacing, uint128 liquidity) = getFeeTickSpacingAndLiquidity(pool);

            if (liquidity == 0 || amountSpecified == 0) {
                return (exactInput ? 0 : type(uint256).max, 0);
            }

            cache.liquidityStart = liquidity;
            cache.feeProtocol = zeroForOne
                ? (slot0Start.feeProtocol % (slot0Start.feeProtocol > 0xff ? 65_536 : 16))
                : (slot0Start.feeProtocol >> (slot0Start.feeProtocol > 0xff ? 16 : 4));

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

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount
            if (cache.feeProtocol > 0) {
                unchecked {
                    uint256 delta = step.feeAmount / cache.feeProtocol;
                    step.feeAmount -= delta;
                }
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

                if (state.liquidity == 0) {
                    break;
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        unchecked {
            (int256 amount0, int256 amount1) = zeroForOne == exactInput
                ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
                : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

            uint256 amountIn = amount0 > 0 ? uint256(amount0) : uint256(amount1);
            uint256 amountOut = amount0 < 0 ? uint256(-amount0) : uint256(-amount1);

            return (amountIn, amountOut);
        }
    }

    function getTickLiquidityNet(IUniswapPool pool, int24 tick) internal view returns (int128 liquidityNet) {
        (, bytes memory data) = address(pool).staticcall(abi.encodeWithSignature("ticks(int24)", tick));
        (, liquidityNet,,,,,,) = abi.decode(data, (uint128, int128, uint256, uint256, int256, uint256, uint256, bool));
    }

    function getFeeTickSpacingAndLiquidity(IUniswapPool pool)
        internal
        view
        returns (uint24 fee, int24 tickSpacing, uint128 liquidity)
    {
        (, bytes memory data) = address(pool).staticcall(abi.encodeWithSignature("fee()"));
        fee = abi.decode(data, (uint24));

        assembly ("memory-safe") {
            mstore(0x40, data)
        }

        (, data) = address(pool).staticcall(abi.encodeWithSignature("tickSpacing()"));
        tickSpacing = abi.decode(data, (int24));

        assembly ("memory-safe") {
            mstore(0x40, data)
        }

        (, data) = address(pool).staticcall(abi.encodeWithSignature("liquidity()"));
        liquidity = abi.decode(data, (uint128));
    }

    function getSlot0(IUniswapPool pool)
        internal
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint256 feeProtocol)
    {
        (, bytes memory data) = address(pool).staticcall(abi.encodeWithSignature("slot0()"));

        (sqrtPriceX96, tick,,,, feeProtocol,) =
            abi.decode(data, (uint160, int24, uint256, uint256, uint256, uint256, bool));

        assembly ("memory-safe") {
            mstore(0x40, data)
        }
    }
}
