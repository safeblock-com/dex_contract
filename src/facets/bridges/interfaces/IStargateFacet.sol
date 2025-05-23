// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateFacet - StargateFacet interface
interface IStargateFacet {
    // =========================
    // events
    // =========================

    /// @notice Emits when a call fails
    event CallFailed(bytes errorMessage);

    // =========================
    // errors
    // =========================

    /// @dev Thrown if native balance is not sufficient
    error StargateFacet_InvalidNativeBalance();

    /// @dev Thrown if msg.sender is not the layerZero endpoint
    error StargateFacet_NotLZEndpoint();

    /// @dev Thrown if asset is not address(0)
    error StargateFacet_UnsupportedAsset();

    // =========================
    // getters
    // =========================

    /// @notice Gets address of the layerZero endpoint
    function lzEndpoint() external view returns (address);

    // =========================
    // quoter
    // =========================

    /// @notice Get quote from Stargate V2
    function quoteV2(
        address poolAddress,
        uint32 dstEid,
        uint256 amountLD,
        address composer,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        external
        view
        returns (uint256 valueToSend, uint256 dstAmount);

    // =========================
    // send
    // =========================

    /// @notice Send message to Stargate V2
    function sendStargateV2(
        address poolAddress,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external;
}
