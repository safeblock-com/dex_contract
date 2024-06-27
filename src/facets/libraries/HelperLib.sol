// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HelperLib {
    uint256 constant E4 = 1e4;

    error UniswapV2_InsufficientInputAmount();
    error UniswapV2_InsufficientOutputAmount();
    error UniswapV2_InsufficientLiquidity();

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE4
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

        unchecked {
            uint256 amountInWithFee = amountIn * (E4 - feeE4);
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = reserveIn * E4 + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE4
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
            revert UniswapV2_InsufficientLiquidity();
        }

        unchecked {
            uint256 numerator = reserveIn * amountOut * E4;
            uint256 denominator = (reserveOut - amountOut) * (E4 - feeE4);
            amountIn = (numerator / denominator) + 1;
        }
    }
}
