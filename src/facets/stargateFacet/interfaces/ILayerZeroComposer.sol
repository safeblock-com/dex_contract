// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ILayerZeroComposer
/// @notice Interface for handling LayerZero message composition in OApp contracts.
/// @dev This interface defines the function for composing LayerZero messages with additional execution.
interface ILayerZeroComposer {
    /// @notice Composes a LayerZero message from an OApp.
    /// @dev This function is called by the LayerZero endpoint to execute additional logic after a message is received.
    /// @param _from The address initiating the composition, typically the OApp where the lzReceive was called.
    /// @param _guid The unique identifier for the corresponding LayerZero src/dst tx.
    /// @param _message The composed message payload in bytes. NOT necessarily the same payload passed via lzReceive.
    /// @param _executor The address of the executor for the composed message.
    /// @param _extraData Additional arbitrary data in bytes passed by the entity who executes the lzCompose.
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    )
        external
        payable;
}
