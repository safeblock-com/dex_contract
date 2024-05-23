// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAxelarGateway {
    function sendToken(
        string memory destinationChain,
        string memory destinationAddress,
        string memory symbol,
        uint256 amount
    ) external;

    function tokenAddresses(string memory symbol) external view returns(address);
}