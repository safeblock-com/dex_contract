// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BinarySearch
/// @notice A library for performing binary search on a bytes array to retrieve facet addresses.
/// @dev Provides an efficient binary search implementation for mapping function selectors to facet addresses
///      stored in a sorted bytes array.
library BinarySearch {
    /// @dev Searches for the facet address associated with a given function selector.
    ///      Performs a binary search on a sorted bytes array containing concatenated function selectors and facet address indices.
    ///      The array is assumed to be sorted by selectors, with selectors occupying 4 bytes and address indices 1 byte per entry.
    ///      If the selector is found, the corresponding facet address is retrieved from the address section of the array.
    /// @param selector The 4-byte function selector to search for.
    /// @param facetsAndSelectors The bytes array containing sorted selectors followed by address indices and facet addresses (20 bytes each).
    /// @param length The number of selector entries in the `facetsAndSelectors` array.
    /// @param addressesOffset The byte offset in `facetsAndSelectors` where the facet addresses start.
    /// @return facet The facet address associated with the selector, or `address(0)` if not found.
    function binarySearch(
        bytes4 selector,
        bytes memory facetsAndSelectors,
        uint256 length,
        uint256 addressesOffset
    )
        internal
        pure
        returns (address facet)
    {
        bytes4 bytes4Mask = bytes4(0xffffffff);

        // binary search
        assembly ("memory-safe") {
            // while(low < high)
            for {
                let offset := add(facetsAndSelectors, 36) // 32 for length + 4 for metadata
                let low
                let high := length
                let mid
                let midValue
                let midSelector
            } lt(low, high) { } {
                mid := shr(1, add(low, high))
                midValue := mload(add(offset, mul(mid, 5)))
                midSelector := and(midValue, bytes4Mask)

                if eq(midSelector, selector) {
                    facet := and(shr(216, midValue), 0xff)
                    facet := shr(96, mload(add(add(addressesOffset, offset), mul(facet, 20))))
                    break
                }

                switch lt(midSelector, selector)
                case 1 { low := add(mid, 1) }
                default { high := mid }
            }
        }
    }
}
