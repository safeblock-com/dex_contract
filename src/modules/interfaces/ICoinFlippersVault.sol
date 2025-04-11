// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlippersVault {
    function deposit(
        bytes32 merchantId,
        bytes32 paymentId,
        address tokenAddress,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    )
        external;
}
