// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

/// @title PoolHelper
library PoolHelper {
    // =========================
    // errors
    // =========================

    /// @notice Throws if `tokenIn` is not in the `pair`
    error EfficientSwapAmount_InvalidTokenIn();

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
            if (token != pool.token1()) {
                revert EfficientSwapAmount_InvalidTokenIn();
            }

            return (false, token0);
        }
    }

    /// @dev return reserve of tokenIn and tokenOut in UniswapV2 pair
    function getReserves(
        IUniswapPool pair,
        bool tokenInIsToken0
    )
        internal
        view
        returns (uint256 reserveInput, uint256 reserveOutput)
    {
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        (reserveInput, reserveOutput) = tokenInIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
