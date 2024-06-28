// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateFactory - StargateFactory interface
interface IStargateFactory {
    /// @notice Gets the address of the stargate pool by its token id
    /// @param poolId: token id of the stargate pool
    /// @return address of the token pool in the stargate protocol
    function getPool(uint256 poolId) external view returns (address);
}
