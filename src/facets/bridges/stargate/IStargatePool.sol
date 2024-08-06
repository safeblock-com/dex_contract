// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateFactory - StargateFactory interface
interface IStargatePool {
    /// @notice Gets the address of the token in the stargate pool
    /// @return address of the token in the stargate pool
    function token() external view returns (address);
}
