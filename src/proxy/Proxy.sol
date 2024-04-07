// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1967Utils } from "./libraries/ERC1967Utils.sol";

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
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    // =========================
    // fallbacks
    // =========================

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`.
    /// Will run if no other function in the contract matches the call data.
    fallback() external payable {
        _fallback();
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`.
    /// Will run if call data is empty.
    receive() external payable {
        _fallback();
    }

    // =========================
    // private functions
    // =========================

    /// @dev Delegates the current call to the address returned by `_implementation()`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _fallback() private {
        address implementation = _implementation();

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

    /// @dev This is a function that should returns the address to which the fallback
    /// function and {_fallback} should delegate.
    function _implementation() private view returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
