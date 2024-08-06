// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStargateComposer } from "../stargate/IStargateComposer.sol";

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

    /// @dev Thrown if msg.sender is not the layerzero endpoint
    error NotLZEndpoint();

    /// @dev Thrown if msg.sender is not the stargate composer
    error NotStargateComposer();

    // =========================
    // getters
    // =========================

    /// @notice Gets address of the layerzero endpoint
    function lzEndpoint() external view returns (address);

    /// @notice Gets address of the stargate composer for cross-chain messaging
    function stargateV1Composer() external view returns (address);

    // =========================
    // quoter
    // =========================

    /// @notice Get quote from Stargate V1
    function quoteV1(
        uint16 dstChainId,
        address composer,
        bytes memory payload,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        view
        returns (uint256);

    /// @notice Get quote from Stargate V2
    function quoteV2(
        address poolAddres,
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

    /// @notice Send message to Stargate V1
    function sendStargateV1(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        uint256 amountLD,
        uint256 amountOutMinLD,
        address receiver,
        bytes memory payload,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        payable
        returns (uint256);

    /// @notice Send message to Stargate V2
    function sendStargateV2(
        address poolAddres,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external
        payable
        returns (uint256);

    // =========================
    // receive
    // =========================

    /// @notice Receive message from Stargate V1
    function sgReceive(
        uint16, /* srcEid */
        bytes memory, /* srcSender */
        uint256, /* nonce */
        address asset,
        uint256 amountLD,
        bytes calldata message
    )
        external
        payable;
}
