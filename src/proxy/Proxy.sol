// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1967Utils } from "./libraries/ERC1967Utils.sol";

/// @dev Initial implementation of an upgradeable proxy.
/// This contract must be deployed as first proxy implementation
/// before any other implementation can be deployed.
contract InitialImplementation {
    error NotInitialOwner(address caller);

    /// @dev Upgrades the implementation of the proxy to `implementation` and calls `data` on it.
    /// If `data` is nonempty, it's used as data in a delegate call to `implementation`.
    /// If caller is not the temporary owner of the proxy (saved in the storage slot not(0)), it will revert.
    /// Slot not(0) is set to 0 when the proxy is upgraded.
    function upgradeTo(address implementation, bytes memory data) external {
        assembly ("memory-safe") {
            if iszero(eq(caller(), sload(not(0)))) {
                // NotInitialOwner selector
                mstore(0, 0x483ffb99)
                mstore(32, caller())
                revert(28, 36)
            }

            sstore(not(0), 0)
        }

        ERC1967Utils.upgradeToAndCall(implementation, data);
    }
}

/// @dev This contract provides a fallback function that delegates all calls to another contract using the EVM
/// instruction `delegatecall`.
///
/// Delegation to the implementation can be triggered manually through the {_fallback} function.
///
/// The success and return data of the delegated call will be returned back to the caller of the proxy.
contract Proxy {
    // =========================
    // constructor
    // =========================

    /// @dev Initializes the upgradeable proxy with an initial implementation specified by `implementation`.
    ///
    /// If `_data` is nonempty, it's used as data in a delegate call to `implementation`. This will typically be an
    /// encoded function call, and allows initializing the storage of the proxy like a Solidity constructor.
    ///
    /// Requirements:
    ///
    /// - If `data` is empty, `msg.value` must be zero.
    constructor(address initialOwner) {
        assembly {
            sstore(not(0), initialOwner) // save caller as temporary owner
        }

        ERC1967Utils.upgradeToAndCall(address(new InitialImplementation()), bytes(""));
    }

    // =========================
    // fallbacks
    // =========================

    /// @dev Fallback function that delegates calls to the address returned by `ERC1967Utils.getImplementation()`.
    /// Will run if no other function in the contract matches the call data.
    fallback() external payable {
        address implementation = ERC1967Utils.getImplementation();

        assembly ("memory-safe") {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Function to receive Native currency.
    receive() external payable { }
}
