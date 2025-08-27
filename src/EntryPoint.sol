// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "./external/Ownable2Step.sol";

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { Utils } from "./libraries/Utils.sol";
import { SSTORE2 } from "./libraries/SSTORE2.sol";
import { BinarySearch } from "./libraries/BinarySearch.sol";
import { TransientStorageLibrary } from "./libraries/TransientStorageLibrary.sol";
import { FeeLibrary } from "./libraries/FeeLibrary.sol";
import { ADDRESS_MASK } from "./libraries/Constants.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";

import { ISignatureTransfer } from "./interfaces/ISignatureTransfer.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

import { IEntryPoint } from "./interfaces/IEntryPoint.sol";

/// @title EntryPoint
/// @notice A proxy contract for dynamic function execution using a diamond-like architecture.
/// @dev Maps function selectors to facet contracts, storing data with SSTORE2 and supporting module management.
///      This contract serves as the main entry point for all interactions with the DEX protocol,
///      routing calls to appropriate facet contracts based on function selectors.
///      It also handles token transfers, fee management, and module registration.
contract EntryPoint is Ownable2Step, UUPSUpgradeable, Initializable, IEntryPoint {
    /// @dev Address where facet and selector bytes are stored using SSTORE2.
    address private immutable _facetsAndSelectorsAddress;

    /// @dev Permit2 contract used for delegated token approvals and transfers.
    ISignatureTransfer private immutable _permit2;

    /// @dev Address of the Wrapped Native token (e.g., WETH).
    IWrappedNative private immutable _wrappedNative;

    /// @dev Mapping of module function signatures to their addresses and indices.
    mapping(bytes4 => bytes32) private _moduleSignatureToAddress;

    /// @dev Array of registered module signatures.
    bytes4[] private _moduleSignatures;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the EntryPoint contract with facet and selector data.
    /// @dev Stores the provided data using SSTORE2 and disables initializers to prevent reinitialization.
    ///      This constructor sets up the core routing mechanism for the diamond pattern implementation.
    /// @param facetsAndSelectors Encoded data containing facet function selectors and addresses.
    /// @param permit2Address Address of the deployed Permit2 contract used for signature-based transfers.
    /// @param wrappedNativeAddress Address of the deployed Wrapped Native token contract (e.g., WETH).
    constructor(bytes memory facetsAndSelectors, address permit2Address, address wrappedNativeAddress) {
        _disableInitializers();
        _permit2 = ISignatureTransfer(permit2Address);
        _wrappedNative = IWrappedNative(wrappedNativeAddress);
        _facetsAndSelectorsAddress = SSTORE2.write({ data: facetsAndSelectors });
    }

    // =========================
    // modifiers
    // ========================

    /// @dev Injects sender address into transient storage before the function call and clears it after.
    /// @param sender The address to store temporarily.
    modifier wrap(address sender) {
        TransientStorageLibrary.setSenderAddress({ senderAddress: sender });

        _;

        TransientStorageLibrary.cleanSenderAddress();
    }

    /// @dev Reverts if the function is not called through a delegatecall from the contract itself.
    modifier onlySelfCall() {
        if (msg.sender != address(this)) {
            revert IEntryPoint.EntryPoint_OnlySelfCall();
        }

        _;
    }

    // =========================
    // initializer
    // =========================

    /// @inheritdoc IEntryPoint
    function initialize(address newOwner) external initializer {
        _transferOwnership(newOwner);
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

    /// @notice Adds a new module with its function signature and address.
    /// @dev Only callable by the owner. Reverts if the module signature already exists.
    ///      Modules extend the functionality of the EntryPoint without requiring a contract upgrade.
    /// @param moduleSignature The 4-byte function signature of the module.
    /// @param moduleAddress The address of the module contract.
    function addModule(bytes4 moduleSignature, address moduleAddress) external onlyOwner {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            let mappingSlot := keccak256(0, 64)

            if sload(mappingSlot) {
                // IEntryPoint.EntryPoint_ModuleAlreadyAdded
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

    /// @notice Updates or removes a module's address for a given function signature.
    /// @dev Only callable by the owner. Reverts if the module does not exist. Set moduleAddress to zero to remove.
    ///      This function allows for dynamic management of modules without requiring a contract upgrade.
    /// @param moduleSignature The 4-byte function signature of the module.
    /// @param moduleAddress The new address of the module contract, or zero to remove the module.
    function updateModule(bytes4 moduleSignature, address moduleAddress) external onlyOwner {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            let mappingSlot := keccak256(0, 64)

            let currentValue := sload(mappingSlot)

            if iszero(currentValue) {
                // IEntryPoint.EntryPoint_ModuleNotAdded
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

    /// @notice Retrieves the address of a module by its function signature.
    /// @dev Returns zero if the module does not exist.
    /// @param moduleSignature The 4-byte function signature of the module.
    /// @return moduleAddress The address of the module contract.
    function getModuleAddress(bytes4 moduleSignature) external view returns (address moduleAddress) {
        moduleAddress = _getModuleAddress(moduleSignature);
    }

    /// @notice Retrieves information about all registered modules.
    /// @dev Returns an array of module signatures and their addresses.
    /// @return info Array of ModuleInfo structs containing module signatures and addresses.
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
    function multicall(bytes[] calldata data) external onlySelfCall {
        Utils.expectEqual({ left: _multicall(data, Utils.decodeTokensAndAmountsArray()).length, right: 0 });
    }

    /// @inheritdoc IEntryPoint
    function multicall(
        IEntryPoint.TokenTransfers calldata tokenTransfers,
        bytes[] calldata data
    )
        external
        payable
        wrap(msg.sender)
    {
        Utils.checkUnique({ addresses: tokenTransfers.tokens });

        (address feeContract, uint256 fee) = FeeLibrary.getFeeContractAddress();

        uint256 length = tokenTransfers.tokens.length;
        bytes32[] memory tokensAndAmounts = new bytes32[](length);
        for (uint256 i = length; i > 0;) {
            unchecked {
                --i;
            }

            uint256 amount = tokenTransfers.amounts[i];
            Utils.expectNotZero({ value: amount });

            address token = tokenTransfers.tokens[i];
            if (token > address(0)) {
                uint256 balanceBefore = TransferHelper.safeGetBalance({ token: token, account: address(this) });
                TransferHelper.safeTransferFrom({ token: token, from: msg.sender, to: address(this), value: amount });
                amount = Utils.compareAmountsWithDifference({
                    greaterValue: TransferHelper.safeGetBalance({ token: token, account: address(this) }),
                    lowerValue: balanceBefore
                });
            } else {
                _wrappedNative.deposit{ value: amount }();
                token = address(_wrappedNative);
            }

            unchecked {
                amount -= FeeLibrary.payFee({ feeContract: feeContract, fee: fee, token: token, amount: amount });
            }

            tokensAndAmounts[i] = Utils.encodeTokenAndAmount({ token: token, amount: amount });
        }

        assembly ("memory-safe") {
            mstore(64, add(tokensAndAmounts, add(32, mul(32, length))))
        }

        Utils.expectEqual({ left: _multicall(data, tokensAndAmounts).length, right: 0 });
    }

    /// @inheritdoc IEntryPoint
    function metaMulticall(
        address sender,
        IEntryPoint.TokenTransfersPermit2 calldata tokenTransfersPermit2,
        bytes[] calldata data
    )
        external
        wrap(sender)
    {
        TransientStorageLibrary.setFeeTokenAndAmount({
            feeToken: tokenTransfersPermit2.feeToken,
            feeAmount: tokenTransfersPermit2.feeAmount
        });

        Utils.expectEqual({
            left: _multicall(
                data,
                _transferTokensPermit2(
                    sender, tokenTransfersPermit2, Utils.hashDataAndSenderDetails({ data: data, sender: msg.sender })
                )
            ).length,
            right: 0
        });
    }

    /// @inheritdoc IEntryPoint
    function multicall(
        IEntryPoint.TokenTransfersPermit2 calldata tokenTransfersPermit2,
        bytes[] calldata data
    )
        external
        wrap(msg.sender)
    {
        Utils.expectEqual({
            left: _multicall(data, _transferTokensPermit2(msg.sender, tokenTransfersPermit2, bytes32(0))).length,
            right: 0
        });
    }

    /// @notice Handles incoming calls by delegating to the appropriate facet or callback address.
    /// @dev Uses the function selector to find the facet or checks for a callback address.
    ///      Reverts if no facet is found. This is the core routing mechanism for the diamond pattern.
    ///      It first checks for a callback address in transient storage, then looks up the facet
    ///      based on the function selector.
    fallback() external payable {
        address facet = TransientStorageLibrary.getCallbackAddress();

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

    /// @notice Allows the contract to receive native currency.
    receive() external payable { }

    // =========================
    // diamond getters
    // =========================

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

    // =========================
    // internal functions
    // =========================

    /// @dev Executes an array of function calls, resolving each to its target facet or module.
    /// @param data Array of calldata function calls to execute in sequence.
    /// @param tokensAndAmounts Encoded tokens and amounts used for routing fees.
    /// @return tokensAndAmounts Updated array with post-call balances after fee deductions.
    function _multicall(bytes[] calldata data, bytes32[] memory tokensAndAmounts) internal returns (bytes32[] memory) {
        address[] memory _facets = _getAddresses(data);

        assembly ("memory-safe") {
            for {
                let length := data.length
                let memoryOffset := add(_facets, 32)
                let ptr := mload(64)
                let cDataStart := data.offset
                let cDataOffset := data.offset
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
                        // IEntryPoint.EntryPoint_FunctionDoesNotExist
                        mstore(0, 0x9365f537)
                        mstore(32, sig)
                        revert(28, 36)
                    }
                }

                let cSize := calldataload(offset)
                calldatacopy(ptr, add(offset, 32), cSize)

                if eq(length, data.length) {
                    let size := 32
                    let dst := add(ptr, cSize)
                    for {
                        let tokensAndAmountsLength := mload(tokensAndAmounts)
                        let tokensAndAmountsOffset := add(tokensAndAmounts, 32)
                    } tokensAndAmountsLength {
                        tokensAndAmountsLength := sub(tokensAndAmountsLength, 1)
                        tokensAndAmountsOffset := add(tokensAndAmountsOffset, 32)
                    } {
                        size := add(size, 32)
                        mstore(dst, mload(tokensAndAmountsOffset))
                        dst := add(dst, 32)
                    }
                    mstore(dst, mload(tokensAndAmounts))
                    cSize := add(cSize, size)
                }

                if sub(length, data.length) {
                    let returnDataSize := sub(returndatasize(), 32)
                    let dst := add(ptr, cSize)
                    returndatacopy(dst, 32, returnDataSize)
                    mstore(add(dst, returnDataSize), mload(dst))
                    cSize := add(cSize, returndatasize())
                }

                if iszero(callcode(gas(), facet, 0, ptr, cSize, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            returndatacopy(tokensAndAmounts, 32, sub(returndatasize(), 32))
        }

        return tokensAndAmounts;
    }

    /// @dev Retrieves the facet address for a given function selector using binary search.
    /// @param selector The 4-byte function selector to look up.
    /// @return facet The address of the facet contract that implements the function.
    function _getAddress(bytes4 selector) internal view returns (address facet) {
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);
        if (facetsAndSelectors.length < 29) {
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

    /// @dev Retrieves facet addresses for an array of function calls.
    ///      Uses binary search to resolve selectors to facet addresses.
    /// @param datas Array of calldata for function calls to resolve.
    /// @return _facets Array of facet addresses corresponding to the selectors.
    function _getAddresses(bytes[] calldata datas) internal view returns (address[] memory _facets) {
        uint256 length = datas.length;
        _facets = new address[](length);
        bytes memory facetsAndSelectors = SSTORE2.read(_facetsAndSelectorsAddress);
        if (facetsAndSelectors.length < 29) {
            revert IEntryPoint.EntryPoint_FunctionDoesNotExist({ selector: 0x00000000 });
        }

        uint256 cDataStart;
        uint256 offset;
        uint256 selectorsLength;
        uint256 addressesOffset;
        assembly ("memory-safe") {
            offset := datas.offset
            cDataStart := datas.offset
            let value := shr(224, mload(add(facetsAndSelectors, 32)))
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
                ++i;
            }
        }
        assembly ("memory-safe") {
            mstore(64, facetsAndSelectors)
        }
    }

    /// @dev Extracts all facet addresses from stored facet and selector data.
    ///      Parses the SSTORE2 data to return an array of facet addresses.
    /// @param facetsAndSelectors Bytes array containing facet and selector data in the format:
    ///                           [metadata][selectors][addresses]
    /// @return _facets Array of facet contract addresses.
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

    /// @dev Retrieves function selectors for a facet at a given index.
    ///      Returns an empty array if the facet index is invalid.
    /// @param facetsAndSelectors Bytes array containing facet and selector data in the format:
    ///                           [metadata][selectors][addresses]
    /// @param facetIndex The index of the facet in the address list.
    /// @return _facetFunctionSelectors Array of 4-byte function selectors that belong to the facet.
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

    /// @dev Retrieves the module address for a given function signature.
    ///      Returns zero if the module is not registered.
    /// @param moduleSignature The 4-byte function signature of the module to look up.
    /// @return moduleAddress The address of the module contract, or zero if not registered.
    function _getModuleAddress(bytes4 moduleSignature) internal view returns (address moduleAddress) {
        assembly ("memory-safe") {
            mstore(0, moduleSignature)
            mstore(32, _moduleSignatureToAddress.slot)
            moduleAddress := and(sload(keccak256(0, 64)), ADDRESS_MASK)
        }
    }

    /// @dev Transfers tokens using Permit2 and updates balances in-place.
    /// @param sender The address who signed the Permit2.
    /// @param tokenTransfersPermit2 Permit2 data and signature.
    /// @param witness Optional EIP-712 hash of calldata and fees.
    /// @return tokensAndAmounts Array of token + updated amount encoded as bytes32.
    function _transferTokensPermit2(
        address sender,
        IEntryPoint.TokenTransfersPermit2 calldata tokenTransfersPermit2,
        bytes32 witness
    )
        internal
        returns (bytes32[] memory tokensAndAmounts)
    {
        Utils.checkUnique({ addresses: tokenTransfersPermit2.tokens });

        uint256 length = tokenTransfersPermit2.tokens.length;
        tokensAndAmounts = new bytes32[](length);

        ISignatureTransfer.TokenPermissions[] memory permitted = new ISignatureTransfer.TokenPermissions[](length);
        ISignatureTransfer.SignatureTransferDetails[] memory transferDetails =
            new ISignatureTransfer.SignatureTransferDetails[](length);

        for (uint256 i = length; i > 0;) {
            unchecked {
                --i;
            }

            uint256 amount = tokenTransfersPermit2.amounts[i];
            Utils.expectNotZero({ value: amount });

            address token = tokenTransfersPermit2.tokens[i];

            permitted[i].token = token;
            permitted[i].amount = amount;

            transferDetails[i].to = address(this);
            transferDetails[i].requestedAmount = amount;

            tokensAndAmounts[i] = Utils.encodeTokenAndAmount({
                token: token,
                amount: TransferHelper.safeGetBalance({ token: token, account: address(this) })
            });
        }

        if (witness == bytes32(0)) {
            _permit2.permitTransferFrom({
                permit: ISignatureTransfer.PermitBatchTransferFrom({
                    permitted: permitted,
                    nonce: tokenTransfersPermit2.nonce,
                    deadline: tokenTransfersPermit2.deadline
                }),
                transferDetails: transferDetails,
                owner: sender,
                signature: tokenTransfersPermit2.signature
            });
        } else {
            _permit2.permitWitnessTransferFrom({
                permit: ISignatureTransfer.PermitBatchTransferFrom({
                    permitted: permitted,
                    nonce: tokenTransfersPermit2.nonce,
                    deadline: tokenTransfersPermit2.deadline
                }),
                transferDetails: transferDetails,
                owner: sender,
                witness: witness,
                witnessTypeString: Utils.getWitnessTypeString(),
                signature: tokenTransfersPermit2.signature
            });
        }

        unchecked {
            (address feeContract, uint256 fee) = FeeLibrary.getFeeContractAddress();

            for (uint256 i = length; i > 0;) {
                --i;

                bytes32 currentValue = tokensAndAmounts[i];

                address token = Utils.bytes32ToAddress({ encodedValue: currentValue });
                uint256 amount = Utils.compareAmountsWithDifference({
                    greaterValue: TransferHelper.safeGetBalance({ token: token, account: address(this) }),
                    lowerValue: Utils.getHighOrder96Bits({ encodedValue: currentValue })
                });

                amount -= FeeLibrary.payFee({ feeContract: feeContract, fee: fee, token: token, amount: amount });

                tokensAndAmounts[i] = Utils.encodeTokenAndAmount({ token: token, amount: amount });
            }
        }

        assembly ("memory-safe") {
            mstore(64, permitted)
        }
    }

    /// @dev Function that should revert `IOwnable.Ownable_Unauthorized` when `msg.sender` is not authorized to upgrade the contract.
    /// Called by {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
