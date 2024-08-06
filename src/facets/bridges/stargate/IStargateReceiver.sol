// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateReceiver - StargateReceiver interface
interface IStargateReceiver {
    /// @notice Function to receive a cross-chain message via StargateComposer
    /// @param chainId: id of source chain
    /// @param srcAddress: source chain msg.sender
    /// @param nonce: nonce of the msg.sender
    /// @param token: address of the token that was received by StargateReceiver
    /// @param amountLD: the exact amount of the `token` received by StargateReceiver
    /// @param payload: byte array for optional StargateReceiver contract call
    function sgReceive(
        uint16 chainId,
        bytes memory srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes memory payload
    )
        external
        payable;
}
