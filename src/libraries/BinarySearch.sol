// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BinarySearch
/// @dev A library for performing binary search on a bytes array to retrieve addresses.
library BinarySearch {
    /// @notice Searches for the `facet` address associated with the given function `selector`.
    /// @dev Uses a binary search algorithm to search within a concatenated bytes array
    /// of facet addresses and function selectors. The array is assumed to be sorted
    /// by `selectors`. If the function `selector` exists, the associated `facet` address is returned.
    /// @param selector The function selector (4 bytes) to search for.
    /// @param facetsAndSelectors The concatenated bytes array of facet addresses and function selectors.
    /// @param length The length of the `selectors` in the `facetsAndSelectors` array.
    /// @param addressesOffset The offset of the `facetAddresses` in the `facetsAndSelectors` array.
    /// @return facet The facet address associated with the given function selector, or address(0) if not found.
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
