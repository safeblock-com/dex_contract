// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPoint - EntryPoint interface
interface IEntryPoint {
    struct ModuleInfo {
        bytes4 moduleSignature;
        address moduleAddress;
    }

    // =========================
    // errors
    // =========================

    /// @dev Thrown when a function selector is not registered in the EntryPoint.
    /// @param selector The 4-byte function selector that does not exist.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    /// @dev Thrown when an invalid fee value is provided during fee configuration.
    error EntryPoint_InvalidFeeValue();

    /// @dev Thrown when attempting to add a module that is already registered.
    /// @param methodSignature The 4-byte function signature of the module.
    error EntryPoint_ModuleAlreadyAdded(bytes4 methodSignature);

    /// @dev Thrown when attempting to update or remove a module that is not registered.
    /// @param methodSignature The 4-byte function signature of the module.
    error EntryPoint_ModuleNotAdded(bytes4 methodSignature);

    // =========================
    // initializer
    // =========================

    /// @notice Initializes a EntryPoint contract.
    function initialize(address newOwner) external;

    /// @notice Executes multiple function calls in a single transaction.
    /// @dev Delegates calls to appropriate facets or modules based on function selectors.

    // =========================
    // multicall
    // =========================

    /// @param data Array of calldata for each function call.
    function multicall(bytes[] calldata data) external payable;

    // =========================
    // admin methods
    // =========================

    /// @notice Sets the fee contract address and fee amount.
    /// @dev Only callable by the owner. Updates the fee configuration in FeeLibrary.
    /// @param feeContractAddress The address of the fee contract.
    /// @param fee The fee amount to set.
    function setFeeContractAddressAndFee(address feeContractAddress, uint256 fee) external;

    /// @notice Retrieves the current fee contract address and fee amount.
    /// @dev Reads the fee configuration from FeeLibrary.
    /// @return feeContractAddress The address of the fee contract.
    /// @return fee The current fee amount.
    function getFeeContractAddressAndFee() external view returns (address feeContractAddress, uint256 fee);

    // =========================
    // diamond getters
    // =========================

    // These functions are expected to be called frequently by tools
    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }

    /// @notice Retrieves all facets and their associated function selectors.
    /// @dev Reads facet and selector data from SSTORE2 storage.
    /// @return _facets Array of Facet structs containing facet addresses and their selectors.
    function facets() external view returns (Facet[] memory _facets);

    /// @notice Retrieves the function selectors for a specific facet.
    /// @dev Returns an empty array if the facet is not found.
    /// @param facet The address of the facet contract.
    /// @return _facetFunctionSelectors Array of 4-byte function selectors.
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory _facetFunctionSelectors);

    /// @notice Retrieves all facet addresses.
    /// @dev Reads facet addresses from SSTORE2 storage.
    /// @return _facets Array of facet contract addresses.
    function facetAddresses() external view returns (address[] memory _facets);

    /// @notice Retrieves the facet address for a given function selector.
    /// @dev Returns zero if the selector is not found.
    /// @param functionSelector The 4-byte function selector.
    /// @return _facet The address of the facet contract.
    function facetAddress(bytes4 functionSelector) external view returns (address _facet);
}
