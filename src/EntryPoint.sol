// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { SSTORE2 } from "./libraries/SSTORE2.sol";
import { BinarySearch } from "./libraries/BinarySearch.sol";

import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { Ownable2Step } from "./external/Ownable2Step.sol";

import { TransientStorageFacetLibrary } from "./libraries/TransientStorageFacetLibrary.sol";

/// @title EntryPoint
/// @notice This contract serves as a proxy for dynamic function execution.
/// @dev It maps function selectors to their corresponding facet contracts.
contract EntryPoint is Ownable2Step, UUPSUpgradeable, Initializable, IEntryPoint {
    //-----------------------------------------------------------------------//
    // function selectors and address indexes are stored as bytes data:      //
    // selector . addressIndex                                               //
    // sample:                                                               //
    // 0xaaaaaaaa <- selector                                                //
    // 0xff <- addressIndex                                                  //
    // 0xaaaaaaaaff <- one element                                           //
    //                                                                       //
    // facetAddressess are stored in the end of the bytes array              //
    //-----------------------------------------------------------------------//

    /// @dev Address where facet and selector bytes are stored using SSTORE2.
    address private immutable _facetsAndSelectorsAddress;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes a EntryPoint contract.
    /// @param facetsAndSelectors A bytes array of bytes4 function selectors and facet addresses.
    ///
    /// @dev Sets up the facet and selectors for the EntryPoint contract,
    /// ensuring that the passed selectors are in order and there are no repetitions.
    /// @dev Ensures that the sizes of selectors and facet addresses match.
    /// @dev The constructor uses SSTORE2 method to stores the combined facet and selectors
    /// in a specified storage location.
    constructor(bytes memory facetsAndSelectors) {
        _disableInitializers();

        _facetsAndSelectorsAddress = SSTORE2.write({ data: facetsAndSelectors });
    }

    /// @inheritdoc IEntryPoint
    function initialize(address newOwner, bytes[] calldata initialCalls) external initializer {
        _transferOwnership(newOwner);

        if (initialCalls.length > 0) {
            _multicall(true, bytes32(0), initialCalls);
        }
    }

    // =========================
    // fallback functions
    // =========================

    /// @inheritdoc IEntryPoint
    function multicall(bytes[] calldata data) external payable {
        _multicall(false, bytes32(0), data);
    }

    /// @inheritdoc IEntryPoint
    function multicall(bytes32 replace, bytes[] calldata data) external payable {
        _multicall(true, replace, data);
    }

    /// @notice Fallback function to execute facet associated with incoming function selectors.
    /// @dev If a facet for the incoming selector is found, it delegates the call to that facet.
    /// @dev If callback address in storage is not address(0) - it delegates the call to that address.
    fallback() external payable {
        address facet = TransientStorageFacetLibrary.getCallbackAddress();

        if (facet == address(0)) {
            facet = _getAddress(msg.sig);

            if (facet == address(0)) {
                revert IEntryPoint.EntryPoint_FunctionDoesNotExist({ selector: msg.sig });
            }
        }

        assembly ("memory-safe") {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Function to receive Native currency.
    receive() external payable { }

    // =======================
    // internal function
    // =======================

    function _multicall(bool isOverride, bytes32 replace, bytes[] calldata data) internal {
        address[] memory facets = _getAddresses(isOverride, data);

        TransientStorageFacetLibrary.setSenderAddress({ senderAddress: msg.sender });

        assembly ("memory-safe") {
            for {
                let length := data.length
                let memoryOffset := add(facets, 32)
                let ptr := mload(64)

                let cDataStart := mul(isOverride, 32)
                let cDataOffset := add(68, cDataStart)
                cDataStart := add(68, cDataStart)

                let facet

                let argReplace
            } length {
                length := sub(length, 1)
                cDataOffset := add(cDataOffset, 32)
                memoryOffset := add(memoryOffset, 32)
            } {
                facet := mload(memoryOffset)
                let offset := add(cDataStart, calldataload(cDataOffset))
                if iszero(facet) {
                    // revert IEntryPoint.EntryPoint_FunctionDoesNotExist(selector);
                    mstore(0, 0x9365f537)
                    mstore(
                        32,
                        and(
                            calldataload(add(offset, 32)),
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                        )
                    )
                    revert(28, 36)
                }

                let cSize := calldataload(offset)
                calldatacopy(ptr, add(offset, 32), cSize)

                // all methods will return only 32 bytes
                if argReplace {
                    if returndatasize() { returndatacopy(add(ptr, argReplace), 0, 32) }
                    argReplace := 0
                }

                if iszero(callcode(gas(), facet, 0, ptr, cSize, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }

                if replace {
                    argReplace := and(replace, 0xffff)
                    replace := shr(16, replace)
                }
            }
        }

        TransientStorageFacetLibrary.setSenderAddress({ senderAddress: address(0) });
    }

    /// @dev Searches for the facet address associated with a function `selector`.
    /// @dev Uses binary search to find the facet address in facetsAndSelectors bytes.
    /// @param selector The function selector.
    /// @return facet The address of the facet contract.
    function _getAddress(bytes4 selector) internal view returns (address facet) {
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);

        if (facetsAndSelectors.length < 24) {
            revert IEntryPoint.EntryPoint_FunctionDoesNotExist({ selector: selector });
        }

        uint256 selectorsLength;
        uint256 addressesOffset;
        assembly ("memory-safe") {
            let value := shr(224, mload(add(32, facetsAndSelectors)))
            selectorsLength := shr(16, value)
            addressesOffset := and(value, 0xffff)
        }

        return BinarySearch.binarySearch({
            selector: selector,
            facetsAndSelectors: facetsAndSelectors,
            length: selectorsLength,
            addressesOffset: addressesOffset
        });
    }

    /// @dev Searches for the facet addresses associated with a function `selectors`.
    /// @dev Uses binary search to find the facet addresses in facetsAndSelectors bytes.
    /// @param datas The calldata to be searched.
    /// @return facets The addresses of the facet contracts.
    function _getAddresses(bool isOverride, bytes[] calldata datas) internal view returns (address[] memory facets) {
        uint256 length = datas.length;
        facets = new address[](length);

        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);

        if (facetsAndSelectors.length < 24) {
            revert IEntryPoint.EntryPoint_FunctionDoesNotExist({ selector: 0x00000000 });
        }

        uint256 cDataStart;
        uint256 offset;
        uint256 selectorsLength;
        uint256 addressesOffset;
        assembly ("memory-safe") {
            cDataStart := mul(isOverride, 32)
            offset := add(68, cDataStart)
            cDataStart := add(68, cDataStart)

            let value := shr(224, mload(add(32, facetsAndSelectors)))
            selectorsLength := shr(16, value)
            addressesOffset := and(value, 0xffff)
        }

        bytes4 selector;
        for (uint256 i; i < length;) {
            assembly ("memory-safe") {
                selector :=
                    and(
                        calldataload(add(cDataStart, add(calldataload(offset), 32))),
                        0xffffffff00000000000000000000000000000000000000000000000000000000
                    )
                offset := add(offset, 32)
            }

            facets[i] = BinarySearch.binarySearch({
                selector: selector,
                facetsAndSelectors: facetsAndSelectors,
                length: selectorsLength,
                addressesOffset: addressesOffset
            });

            unchecked {
                // increment loop counter
                ++i;
            }
        }

        assembly ("memory-safe") {
            // re-use unnecessary memory
            mstore(64, facetsAndSelectors)
        }
    }

    /// @dev Function that should revert IEntryPoint.when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
