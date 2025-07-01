// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { CAST_INT_CONSTANT } from "./Constants.sol";

import { IErrors } from "../interfaces/IErrors.sol";

library Utils {
    /// @dev Validates that the `greaterValue` is greater than the `lowerValue`.
    ///      Reverts with `IErrors.ValueLowerThanExpected` if the condition is not met.
    /// @param greaterValue The value which is expected to be greater.
    /// @param lowerValue The value which is expected to be lower.
    /// @return difference The difference between the two values.
    function compareAmounts(uint256 greaterValue, uint256 lowerValue) internal pure returns (uint256 difference) {
        if (greaterValue < lowerValue) {
            revert IErrors.ValueLowerThanExpected({
                expectedGreaterValue: greaterValue,
                expectedLowerBalance: lowerValue
            });
        }
        unchecked {
            difference = greaterValue - lowerValue;
        }
    }

    function expectEqual(uint256 left, uint256 right) internal pure {
        assembly ("memory-safe") {
            if sub(left, right) {
                // IErrors.ValuesNotEqual()
                mstore(0, 0xc8431659)
                revert(28, 4)
            }
        }
    }

    /// @dev Converts a uint256 value to an address.
    /// @param encodedAddress The uint256 value to convert.
    /// @return result The resulting address.
    function uintToAddress(uint256 encodedAddress) internal pure returns (address result) {
        assembly ("memory-safe") {
            result := encodedAddress
        }
    }

    /// @dev Performs a low-level call to a contract and returns success status.
    ///      Used to call Uniswap V2 swap functions with different selectors.
    /// @param addr The target contract address.
    /// @param data The encoded function call data.
    /// @return success True if the call succeeds, false otherwise.
    function makeCall(address addr, bytes memory data) internal returns (bool success) {
        (success,) = addr.call(data);
    }

    /// @dev Returns the address of this contract as a bytes32 value.
    ///      Used to encode the contract address for swap destinations.
    /// @return result The contract address in bytes32 format.
    function addressThisBytes32() internal view returns (bytes32 result) {
        assembly ("memory-safe") {
            result := address()
        }
    }

    function checkIntCast(uint256 amount) internal pure {
        // cast a uint256 to a int256, revert on overflow
        // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol#L24
        if (amount > CAST_INT_CONSTANT) {
            revert IErrors.InvalidIntCast();
        }
    }
}
