// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { CAST_INT_CONSTANT, ADDRESS_MASK } from "./Constants.sol";

/// @title Utils
/// @notice General utility library for encoding, validation, array manipulation, and hashing in the router system.
/// @dev Includes math validation, calldata decoding, address masking, Permit2 witness hashing, and custom data encoders.
///      This library is used throughout the protocol to handle various utility functions.
library Utils {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when a uint256 value cannot be safely cast to int256.
    error InvalidIntCast();

    /// @dev Thrown when an expected greater value is actually lower than the comparison value.
    /// @param expectedGreaterValue The value that was expected to be larger.
    /// @param expectedLowerBalance The value that was expected to be smaller.
    error ValueLowerThanExpected(uint256 expectedGreaterValue, uint256 expectedLowerBalance);

    /// @dev Thrown when two values that were expected to match do not.
    /// @param left The first value.
    /// @param right The second value.
    error ValuesNotEqual(uint256 left, uint256 right);

    /// @dev Thrown when duplicate tokens are detected in an array that must be unique.
    error DuplicateToken();

    /// @dev Thrown when a value is expected to be non-zero but is zero.
    error UnexpectedZeroValue();

    // =========================
    // functions
    // =========================

    /// @notice Checks that `greaterValue > lowerValue` and returns their difference.
    /// @dev Reverts if the condition is not satisfied.
    /// @param greaterValue Expected to be greater.
    /// @param lowerValue Expected to be lower.
    /// @return difference The subtraction result.
    function compareAmountsWithDifference(
        uint256 greaterValue,
        uint256 lowerValue
    )
        internal
        pure
        returns (uint256 difference)
    {
        compareAmounts({ greaterValue: greaterValue, lowerValue: lowerValue });
        unchecked {
            difference = greaterValue - lowerValue;
        }
    }

    /// @notice Reverts if `greaterValue < lowerValue`.
    /// @param greaterValue The value expected to be greater
    /// @param lowerValue The value expected to be lower
    function compareAmounts(uint256 greaterValue, uint256 lowerValue) internal pure {
        assembly ("memory-safe") {
            if lt(greaterValue, lowerValue) {
                // ValueLowerThanExpected(uint256,uint256) selector
                mstore(0, 0xa80090fd)
                mstore(32, greaterValue)
                mstore(64, lowerValue)
                revert(28, 68)
            }
        }
    }

    /// @notice Reverts if `left != right`.
    /// @param left The first value to compare
    /// @param right The second value to compare
    function expectEqual(uint256 left, uint256 right) internal pure {
        assembly ("memory-safe") {
            if sub(left, right) {
                // ValuesNotEqual(uint256,uint256) selector
                mstore(0, 0x460b9939)
                mstore(32, left)
                mstore(64, right)
                revert(28, 68)
            }
        }
    }

    /// @notice Reverts with custom error if `value == 0`.
    /// @param value The value to check
    function expectNotZero(uint256 value) internal pure {
        assembly ("memory-safe") {
            if iszero(value) {
                // UnexpectedZeroValue() selector
                mstore(0, 0x75a0be41)
                revert(28, 4)
            }
        }
    }

    /// @notice Performs a low-level call and returns success.
    /// @param addr The address to call
    /// @param data The calldata to send with the call
    /// @return success Whether the call was successful
    function makeCall(address addr, bytes memory data) internal returns (bool success) {
        (success,) = addr.call(data);
    }

    /// @notice Validates whether a uint256 can be safely casted to int256.
    /// @param amount The uint256 value to check for safe casting
    function checkIntCast(uint256 amount) internal pure {
        // cast a uint256 to a int256, revert on overflow
        // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol#L24
        if (amount > CAST_INT_CONSTANT) {
            revert InvalidIntCast();
        }
    }

    /// @notice Returns current contract address as bytes32.
    /// @return result The current contract address encoded as bytes32
    function addressThisBytes32() internal view returns (bytes32 result) {
        assembly ("memory-safe") {
            result := address()
        }
    }

    /// @notice Returns address as bytes32.
    /// @return result The address encoded as bytes32
    function addressToBytes32(address addr) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            result := addr
        }
    }

    /// @notice Extracts high 96 bits from a bytes32.
    /// @param encodedValue The bytes32 value to extract bits from
    /// @return result The extracted high 96 bits as uint256
    function getHighOrder96Bits(bytes32 encodedValue) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := shr(160, encodedValue)
        }
    }

    /// @notice Extracts address from lower 160 bits of a bytes32.
    /// @param encodedValue The bytes32 value to extract address from
    /// @return result The extracted address
    function bytes32ToAddress(bytes32 encodedValue) internal pure returns (address result) {
        assembly ("memory-safe") {
            result := and(encodedValue, ADDRESS_MASK)
        }
    }

    /// @notice Encodes token address and amount into a bytes32 word.
    /// @param token The token address to encode
    /// @param amount The amount to encode
    /// @return result The encoded bytes32 word containing both token and amount
    function encodeTokenAndAmount(address token, uint256 amount) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            result := add(shl(160, amount), token)
        }
    }

    /// @notice Encodes two uint128 values into a single uint256.
    /// @param lowerBitsAmount The amount to encode in the lower 128 bits
    /// @param upperBitsAmount The amount to encode in the upper 128 bits
    /// @return result The encoded uint256 containing both amounts
    function encodeTwoAmounts(
        uint256 lowerBitsAmount,
        uint256 upperBitsAmount
    )
        internal
        pure
        returns (uint256 result)
    {
        assembly ("memory-safe") {
            result := add(shl(128, upperBitsAmount), lowerBitsAmount)
        }
    }

    /// @notice Decodes two uint128 values from a single uint256.
    /// @param encodedValue The uint256 value containing two encoded amounts
    /// @return lowerBitsAmount The amount decoded from the lower 128 bits
    /// @return upperBitsAmount The amount decoded from the upper 128 bits
    function decodeTwoAmounts(uint256 encodedValue)
        internal
        pure
        returns (uint256 lowerBitsAmount, uint256 upperBitsAmount)
    {
        assembly ("memory-safe") {
            upperBitsAmount := shr(128, encodedValue)
            lowerBitsAmount := shr(128, shl(128, encodedValue))
        }
    }

    /// @notice EIP-712 type string for DataAndSenderDetails struct
    /// @dev Used for Permit2 witness hashing in meta transactions
    string internal constant DATA_AND_SENDER_DETAILS_TYPE = "DataAndSenderDetails(bytes[] data,address sender)";

    /// @notice EIP-712 typehash for DataAndSenderDetails struct
    /// @dev Precomputed hash of DATA_AND_SENDER_DETAILS_TYPE
    bytes32 internal constant DATA_AND_SENDER_DETAILS_TYPEHASH =
        0x1db49191f6aedd50e82a59daff95f48b956d744441ff81e8755316b05950578a;

    /// @notice EIP-712 type string for TokenPermissions struct
    /// @dev Used for Permit2 witness hashing in meta transactions
    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    /// @notice Returns EIP-712 Permit2 hash for data and sender.
    /// @param data Array of bytes data to be hashed
    /// @param sender The address of the sender
    /// @return hash The computed EIP-712 hash
    function hashDataAndSenderDetails(bytes[] calldata data, address sender) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            let length := data.length
            let ptr := mload(64)
            for {
                let dst := ptr
                let offset := data.offset
                let lengthCache := length
            } lengthCache {
                lengthCache := sub(lengthCache, 1)
                offset := add(offset, 32)
                dst := add(dst, 32)
            } {
                let dataOffset := add(data.offset, calldataload(offset))
                let dataLength := calldataload(dataOffset)
                calldatacopy(dst, add(dataOffset, 32), dataLength)
                mstore(dst, keccak256(dst, dataLength))
            }
            mstore(add(ptr, 32), keccak256(ptr, mul(length, 32)))
            mstore(ptr, DATA_AND_SENDER_DETAILS_TYPEHASH)
            mstore(add(ptr, 64), sender)
            hash := keccak256(ptr, 96)
        }
    }

    /// @notice Returns full EIP-712 Permit2 witness type string.
    /// @return The concatenated EIP-712 type string for Permit2 witness
    function getWitnessTypeString() internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "DataAndSenderDetails dataAndSenderDetails)", DATA_AND_SENDER_DETAILS_TYPE, TOKEN_PERMISSIONS_TYPE
            )
        );
    }

    /// @notice Decodes a bytes32[] from calldata tail segment.
    /// @return tokensAndAmounts The decoded array of token and amount pairs
    function decodeTokensAndAmountsArray() internal pure returns (bytes32[] memory tokensAndAmounts) {
        assembly ("memory-safe") {
            tokensAndAmounts := mload(64)

            let length := calldataload(sub(calldatasize(), 32))
            mstore(tokensAndAmounts, length)
            mstore(64, add(tokensAndAmounts, add(32, mul(32, length))))
            if length {
                calldatacopy(add(tokensAndAmounts, 32), sub(calldatasize(), add(32, mul(32, length))), mul(32, length))
            }
        }
    }

    /// @notice Creates a bytes32[] array from tokens and amounts.
    /// @param wrappedNative The address of the wrapped native token
    /// @param tokens Array of token addresses
    /// @param amounts Array of corresponding amounts
    /// @return tokensAndAmounts The created array of encoded token and amount pairs
    function createTokensAndAmountsArray(
        address wrappedNative,
        address[] calldata tokens,
        uint256[] calldata amounts
    )
        internal
        pure
        returns (bytes32[] memory tokensAndAmounts)
    {
        unchecked {
            assembly ("memory-safe") {
                tokensAndAmounts := mload(64)
            }

            uint256 length = amounts.length;
            for (uint256 i; i < length; i++) {
                address token = tokens[i];
                addElementToArrayOrAddAmount({
                    tokensAndAmounts: tokensAndAmounts,
                    element: encodeTokenAndAmount({ token: token > address(0) ? token : wrappedNative, amount: amounts[i] })
                });
            }
        }
    }

    /// @notice Retrieves and removes a token from the array. Returns its amount.
    /// @param tokensAndAmounts The array of encoded token and amount pairs
    /// @param token The token address to search for
    /// @return amount The amount associated with the token
    function getAmountFromArrayAndDelete(
        bytes32[] memory tokensAndAmounts,
        address token
    )
        internal
        pure
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            for {
                let length := mload(tokensAndAmounts)
                let offset := add(tokensAndAmounts, mul(32, length)) // last element of the array
                let i
                let offsetCache := offset
            } lt(i, length) {
                i := add(i, 1)
                offsetCache := sub(offsetCache, 32)
            } {
                let tokenAndAmount := mload(offsetCache)
                if eq(token, and(tokenAndAmount, ADDRESS_MASK)) {
                    mstore(offsetCache, mload(offset))
                    mstore(tokensAndAmounts, sub(length, 1))
                    amount := shr(160, tokenAndAmount)
                    break
                }
            }
        }
    }

    /// @notice Adds an entry to the array or increases the amount if it already exists.
    /// @param tokensAndAmounts The array of encoded token and amount pairs
    /// @param element The encoded token and amount pair to add or update
    function addElementToArrayOrAddAmount(bytes32[] memory tokensAndAmounts, bytes32 element) internal pure {
        assembly ("memory-safe") {
            let length := mload(tokensAndAmounts)
            let flag := 1
            for {
                let i := length
                let offset := add(tokensAndAmounts, 32)
            } i {
                i := sub(i, 1)
                offset := add(offset, 32)
            } {
                let value := mload(offset)
                if eq(and(element, ADDRESS_MASK), and(value, ADDRESS_MASK)) {
                    mstore(offset, add(value, and(element, not(ADDRESS_MASK))))
                    flag := 0
                    break
                }
            }

            if flag {
                let offset := add(tokensAndAmounts, add(32, mul(32, length)))
                mstore(offset, element)
                mstore(tokensAndAmounts, add(length, 1))
                mstore(64, add(offset, 32))
            }
        }
    }

    /// @notice Ensures all addresses in an array are unique.
    /// @param addresses The array of addresses to check for uniqueness
    function checkUnique(address[] calldata addresses) internal pure {
        unchecked {
            uint256 length = addresses.length;
            if (length > 0) {
                for (uint256 i; i < length - 1; ++i) {
                    for (uint256 j = i + 1; j < length; ++j) {
                        if (addresses[i] == addresses[j]) {
                            revert DuplicateToken();
                        }
                    }
                }
            }
        }
    }
}
