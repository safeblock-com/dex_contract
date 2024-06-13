// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { SSTORE2 } from "./libraries/SSTORE2.sol";
import { BinarySearch } from "./libraries/BinarySearch.sol";

import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { Ownable2Step } from "./external/Ownable2Step.sol";

/// @title EntryPoint
/// @notice This contract serves as a proxy for dynamic function execution.
/// @dev It maps function selectors to their corresponding facet contracts.
contract EntryPoint is UUPSUpgradeable, Ownable2Step, Initializable, IEntryPoint {
    //-----------------------------------------------------------------------//
    // function selectors and facet addresses are stored as bytes data:      //
    // selector . address                                                    //
    // sample:                                                               //
    // 0xaaaaaaaa <- selector                                                //
    // 0xffffffffffffffffffffffffffffffffffffffff <- address                 //
    // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff <- one element     //
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
        _facetsAndSelectorsAddress = SSTORE2.write({ data: facetsAndSelectors });
    }

    /// @notice Initializes a EntryPoint contract.
    function initialize(address newOwner, bytes[] calldata initialCalls) external initializer {
        _transferOwnership(newOwner);

        _multicall(initialCalls);
    }

    // =========================
    // fallback function
    // =========================

    /// @inheritdoc IEntryPoint
    function multicall(bytes[] calldata data) external payable {
        _multicall(data);
    }

    /// @notice Fallback function to execute facet associated with incoming function selectors.
    /// @dev If a facet for the incoming selector is found, it delegates the call to that facet.
    fallback() external payable {
        address facet = _getAddress(msg.sig);

        if (facet == address(0)) {
            revert EntryPoint_FunctionDoesNotExist(msg.sig);
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

    /// @notice Receive function to receive Native currency.
    receive() external payable { }

    // =======================
    // internal function
    // =======================

    function _multicall(bytes[] calldata data) internal {
        address[] memory facets = _getAddresses(data);

        assembly ("memory-safe") {
            for {
                let length := data.length
                let memoryOffset := add(facets, 32)
                let ptr := mload(64)

                let cDataStart := 68
                let cDataOffset := 68

                let facet
            } length {
                length := sub(length, 1)
                cDataOffset := add(cDataOffset, 32)
                memoryOffset := add(memoryOffset, 32)
            } {
                facet := mload(memoryOffset)
                let offs := add(cDataStart, calldataload(cDataOffset))
                if iszero(facet) {
                    // revert EntryPoint_FunctionDoesNotExist(selector);
                    mstore(0, 0x9365f537)
                    mstore(
                        32,
                        and(
                            calldataload(add(offs, 32)),
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                        )
                    )
                    revert(28, 36)
                }

                let cSize := calldataload(offs)
                calldatacopy(ptr, add(offs, 32), cSize)

                if iszero(delegatecall(gas(), facet, ptr, cSize, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    /// @dev Searches for the facet address associated with a function `selector`.
    /// @dev Uses binary search to find the facet address in facetsAndSelectors bytes.
    /// @param selector The function selector.
    /// @return facet The address of the facet contract.
    function _getAddress(bytes4 selector) internal view returns (address facet) {
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);

        if (facetsAndSelectors.length < 24) {
            revert EntryPoint_FunctionDoesNotExist(selector);
        }

        return BinarySearch.binarySearch({ selector: selector, facetsAndSelectors: facetsAndSelectors });
    }

    /// @dev Searches for the facet addresses associated with a function `selectors`.
    /// @dev Uses binary search to find the facet addresses in facetsAndSelectors bytes.
    /// @param datas The calldata to be searched.
    /// @return facets The addresses of the facet contracts.
    function _getAddresses(bytes[] calldata datas) internal view returns (address[] memory facets) {
        uint256 length = datas.length;
        facets = new address[](length);

        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);

        if (facetsAndSelectors.length < 24) {
            revert EntryPoint_FunctionDoesNotExist(0x00000000);
        }

        uint256 cDataStart = 68;
        uint256 offset = 68;

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

            facets[i] = BinarySearch.binarySearch({ selector: selector, facetsAndSelectors: facetsAndSelectors });

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

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
