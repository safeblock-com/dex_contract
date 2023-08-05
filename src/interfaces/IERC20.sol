// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address to, uint256 amount) external returns (bool);

    function balanceOf(address holder) external view returns (uint256);

    function allowance(
        address spender,
        address recipient
    ) external view returns (uint256);

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}
