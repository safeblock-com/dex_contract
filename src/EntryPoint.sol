// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { SSTORE2 } from "./libraries/SSTORE2.sol";
import { BinarySearch } from "./libraries/BinarySearch.sol";

import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { Ownable2Step } from "./external/Ownable2Step.sol";

import { TransientStorageFacetLibrary } from "./libraries/TransientStorageFacetLibrary.sol";
import { FeeLibrary } from "./libraries/FeeLibrary.sol";

import { ADDRESS_MASK } from "./libraries/Constants.sol";

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
    // facetAddresses are stored in the end of the bytes array              //
    //-----------------------------------------------------------------------//

    /// @dev Address where facet and selector bytes are stored using SSTORE2.
    address private immutable _facetsAndSelectorsAddress;

    mapping(bytes4 => bytes32) private _moduleSignatureToAddress;
    bytes4[] private _moduleSignatures;

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
            _multicall(true, initialCalls);
        }
    }

    // =========================
    // admin methods
    // =========================

    /// @inheritdoc IEntryPoint
    function setFeeContractAddressAndFee(address feeContractAddress, uint256 fee) external onlyOwner {
        FeeLibrary.setFeeContractAddress(feeContractAddress, fee);
    }

    /// @inheritdoc IEntryPoint
    function getFeeContractAddressAndFee() external view returns (address feeContractAddress, uint256 fee) {
        (feeContractAddress, fee) = FeeLibrary.getFeeContractAddress();
    }

    function addModule(bytes4 moduleSignature, address moduleAddress) external onlyOwner {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            let mappingSlot := keccak256(0, 64)

            if sload(mappingSlot) {
                // revert IEntryPoint.EntryPoint_ModuleAlreadyAdded(moduleSignature);
                mstore(0, 0xefd5d8e4)
                mstore(32, moduleSignature)

                revert(28, 36)
            }

            let index := sload(_moduleSignatures.slot)
            sstore(_moduleSignatures.slot, add(index, 1))

            let offset := div(index, 8)
            let position := mod(index, 8)

            mstore(0, _moduleSignatures.slot)
            let slot := add(keccak256(0, 32), offset)
            sstore(slot, add(sload(slot), shl(mul(32, position), shr(224, moduleSignature))))

            sstore(mappingSlot, add(shl(160, index), moduleAddress))
        }
    }

    function updateModule(bytes4 moduleSignature, address moduleAddress) external onlyOwner {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            let mappingSlot := keccak256(0, 64)

            let currentValue := sload(mappingSlot)

            if iszero(currentValue) {
                // revert IEntryPoint.EntryPoint_ModuleNotAdded(moduleSignature);
                mstore(0, 0xeac1ef32)
                mstore(32, moduleSignature)

                revert(28, 36)
            }

            switch moduleAddress
            case 0 {
                sstore(mappingSlot, 0)

                let index := shr(160, currentValue)
                let length := sub(sload(_moduleSignatures.slot), 1)
                sstore(_moduleSignatures.slot, length)

                if length {
                    mstore(0, _moduleSignatures.slot)

                    let slot := keccak256(0, 32)

                    let endOffset := div(length, 8)
                    let endPosition := mod(length, 8)

                    let indexOffset := div(index, 8)
                    let indexPosition := mod(index, 8)

                    let endElement := and(shr(mul(32, endPosition), sload(add(slot, endOffset))), 0xffffffff)

                    sstore(
                        add(slot, indexOffset),
                        add(
                            shl(mul(32, indexPosition), endElement),
                            and(sload(add(slot, indexOffset)), not(shl(mul(32, indexPosition), 0xffffffff)))
                        )
                    )
                }
            }
            default { sstore(mappingSlot, add(moduleAddress, and(currentValue, not(ADDRESS_MASK)))) }
        }
    }

    function getModuleAddress(bytes4 moduleSignature) external view returns (address moduleAddress) {
        moduleAddress = _getModuleAddress(moduleSignature);
    }

    function getModules() external view returns (IEntryPoint.ModuleInfo[] memory info) {
        uint256 length = _moduleSignatures.length;

        info = new IEntryPoint.ModuleInfo[](length);

        for (uint256 i; i < length;) {
            bytes4 moduleSignature = _moduleSignatures[i];
            info[i] = IEntryPoint.ModuleInfo({
                moduleSignature: moduleSignature,
                moduleAddress: _getModuleAddress(moduleSignature)
            });

            unchecked {
                ++i;
            }
        }
    }

    // =========================
    // fallback functions
    // =========================

    /// @inheritdoc IEntryPoint
    function multicall(bytes[] calldata data) external payable {
        _multicall(false, data);
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
    // diamond getters
    // =======================

    /// @inheritdoc IEntryPoint
    function facets() external view returns (IEntryPoint.Facet[] memory _facets) {
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);
        address[] memory _facetsRaw = _getAddresses(facetsAndSelectors);

        _facets = new IEntryPoint.Facet[](_facetsRaw.length);

        for (uint256 i; i < _facetsRaw.length;) {
            _facets[i].facet = _facetsRaw[i];
            _facets[i].functionSelectors = _getFacetFunctionSelectors(facetsAndSelectors, i);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IEntryPoint
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory _facetFunctionSelectors) {
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);
        address[] memory _facets = _getAddresses(facetsAndSelectors);

        uint256 facetIndex = type(uint64).max;
        for (uint256 i; i < _facets.length;) {
            if (_facets[i] == facet) {
                facetIndex = i;
                break;
            }
            unchecked {
                ++i;
            }
        }

        _facetFunctionSelectors = _getFacetFunctionSelectors(facetsAndSelectors, facetIndex);
    }

    /// @inheritdoc IEntryPoint
    function facetAddresses() external view returns (address[] memory _facets) {
        _facets = _getAddresses(SSTORE2.read(_facetsAndSelectorsAddress));
    }

    /// @inheritdoc IEntryPoint
    function facetAddress(bytes4 functionSelector) external view returns (address _facet) {
        _facet = _getAddress(functionSelector);
    }

    // =======================
    // internal function
    // =======================

    /// @notice Function to execute facets associated with incoming function selectors.
    function _multicall(bool isOffset, bytes[] calldata data) internal {
        address[] memory _facets = _getAddresses(isOffset, data);

        TransientStorageFacetLibrary.setSenderAddress({ senderAddress: msg.sender });

        assembly ("memory-safe") {
            for {
                let length := data.length
                let memoryOffset := add(_facets, 32)
                let ptr := mload(64)

                let cDataStart := 68
                let cDataOffset := 68

                if isOffset {
                    cDataStart := add(cDataStart, 32)
                    cDataOffset := add(cDataOffset, 32)
                }

                let facet
            } length {
                length := sub(length, 1)
                cDataOffset := add(cDataOffset, 32)
                memoryOffset := add(memoryOffset, 32)
            } {
                facet := mload(memoryOffset)
                let offset := add(cDataStart, calldataload(cDataOffset))
                if iszero(facet) {
                    let sig :=
                        and(
                            calldataload(add(offset, 32)),
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                        )

                    mstore(0, sig)
                    mstore(32, _moduleSignatureToAddress.slot)
                    facet := and(sload(keccak256(0, 64)), ADDRESS_MASK)

                    if iszero(facet) {
                        // revert IEntryPoint.EntryPoint_FunctionDoesNotExist(selector);
                        mstore(0, 0x9365f537)
                        mstore(32, sig)
                        revert(28, 36)
                    }
                }

                let cSize := calldataload(offset)
                calldatacopy(ptr, add(offset, 32), cSize)

                if iszero(callcode(gas(), facet, 0, ptr, cSize, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
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
    /// @return _facets The addresses of the facet contracts.
    function _getAddresses(bool isOffset, bytes[] calldata datas) internal view returns (address[] memory _facets) {
        uint256 length = datas.length;
        _facets = new address[](length);

        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);

        if (facetsAndSelectors.length < 24) {
            revert IEntryPoint.EntryPoint_FunctionDoesNotExist({ selector: 0x00000000 });
        }

        uint256 cDataStart;
        uint256 offset;
        uint256 selectorsLength;
        uint256 addressesOffset;
        assembly ("memory-safe") {
            cDataStart := mul(isOffset, 32)
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

            _facets[i] = BinarySearch.binarySearch({
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

    /// @dev Returns the addresses of the facets.
    function _getAddresses(bytes memory facetsAndSelectors) internal pure returns (address[] memory _facets) {
        assembly ("memory-safe") {
            let counter
            for {
                _facets := mload(64)
                let addressesOffset :=
                    add(
                        add(facetsAndSelectors, 36), // 32 for length + 4 for metadata
                        and(shr(224, mload(add(32, facetsAndSelectors))), 0xffff)
                    )
                let offset := add(_facets, 32)
            } 1 {
                offset := add(offset, 32)
                addressesOffset := add(addressesOffset, 20)
            } {
                let value := shr(96, mload(addressesOffset))
                if iszero(value) { break }
                mstore(offset, value)
                counter := add(counter, 1)
            }

            mstore(_facets, counter)
            mstore(64, add(mload(64), add(32, mul(counter, 32))))
        }
    }

    /// @dev Returns the selectors of the facet with the given index.
    function _getFacetFunctionSelectors(
        bytes memory facetsAndSelectors,
        uint256 facetIndex
    )
        internal
        pure
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        assembly ("memory-safe") {
            let counter
            for {
                _facetFunctionSelectors := mload(64)
                let offset := add(_facetFunctionSelectors, 32)
                let selectorsOffset := add(facetsAndSelectors, 36) // 32 for length + 4 for metadata
                let selectorsLength := shr(240, mload(add(32, facetsAndSelectors)))
            } selectorsLength {
                selectorsLength := sub(selectorsLength, 1)
                selectorsOffset := add(selectorsOffset, 5)
            } {
                let selector := mload(selectorsOffset)
                if eq(and(shr(216, selector), 0xff), facetIndex) {
                    mstore(offset, and(selector, 0xffffffff00000000000000000000000000000000000000000000000000000000))
                    counter := add(counter, 1)
                    offset := add(offset, 32)
                }
            }

            mstore(_facetFunctionSelectors, counter)
            mstore(64, add(mload(64), add(32, mul(counter, 32))))
        }
    }

    /// @dev Returns the address of the module address with the given function signature.
    function _getModuleAddress(bytes4 moduleSignature) internal view returns (address moduleAddress) {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            moduleAddress := and(sload(keccak256(0, 64)), ADDRESS_MASK)
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
