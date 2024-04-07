// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    // V3
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    )
        external
        returns (int256 amount0, int256 amount1);

    // V2
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    // V2 without data
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint256, uint256, uint32);
}
