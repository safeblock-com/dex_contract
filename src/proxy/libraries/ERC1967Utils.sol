// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library ERC1967Utils {
    // =========================
    // immutable storage
    // =========================

    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // =========================
    // events
    // =========================

    /// @dev Emitted when the implementation is upgraded.
    event Upgraded(address indexed implementation);

    // =========================
    // errors
    // =========================

    /// @dev The `implementation` of the proxy is invalid.
    error ERC1967_InvalidImplementation(address implementation);

    /// @dev An upgrade function sees `msg.value > 0` that may be lost.
    error ERC1967_NonPayable();

    /// @dev A call to an address target failed. The target may have reverted.
    error ERC1967_FailedInnerCall();

    // =========================
    // main functions
    // =========================

    /// @dev Returns the current implementation address.
    function getImplementation() internal view returns (address implementation) {
        assembly ("memory-safe") {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Stores a new address in the EIP1967 implementation slot.
    function setImplementation(address newImplementation) internal {
        assembly ("memory-safe") {
            if iszero(extcodesize(newImplementation)) {
                // "ERC1967_InvalidImplementation(address)" selector
                mstore(0, 0x4a4a0aa2)
                mstore(32, newImplementation)
                revert(28, 36)
            }

            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /// @dev Performs implementation upgrade with additional setup call if data is nonempty.
    /// This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
    /// to avoid stuck value in the contract.
    ///
    /// Emits an {IERC1967-Upgraded} event.
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            (bool success, bytes memory returndata) = newImplementation.delegatecall(data);

            if (!success) {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    assembly ("memory-safe") {
                        revert(add(32, returndata), mload(returndata))
                    }
                } else {
                    revert ERC1967_FailedInnerCall();
                }
            }
        } else {
            _checkNonPayable();
        }
    }

    // =========================
    // private functions
    // =========================

    /// @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
    /// if an upgrade doesn't perform an initialization call.
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967_NonPayable();
        }
    }
}
