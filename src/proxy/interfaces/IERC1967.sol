// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
interface IERC1967 {
    /// @dev Emitted when the implementation is upgraded.
    event Upgraded(address indexed implementation);
}
