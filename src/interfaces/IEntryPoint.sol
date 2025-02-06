// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPoint - EntryPoint interface
interface IEntryPoint {
    // =========================
    // errors
    // =========================

    /// @notice Throws when the function does not exist in the EntryPoint.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    // =========================
    // initializer
    // =========================

    /// @notice Initializes a EntryPoint contract.
    function initialize(address newOwner, bytes[] calldata initialCalls) external;

    /// @notice Executes multiple calls in a single transaction.
    /// @dev Iterates through an array of call data and executes each call.
    /// If any call fails, the function reverts with the original error message.
    /// @param data An array of call data to be executed.
    function multicall(bytes[] calldata data) external payable;

    /// @notice Executes multiple calls in a single transaction.
    /// @dev Iterates through an array of call data and executes each call.
    /// If any call fails, the function reverts with the original error message.
    /// @param replace The offsets to replace.
    /// @dev The offsets are encoded as uint16 in bytes32.
    ///     If the first 16-bit bit after a call is non-zero,
    ///     the result of the call replaces the calldata for the next call at that offset.
    /// @param data An array of call data to be executed.
    function multicall(bytes32 replace, bytes[] calldata data) external payable;

    // =========================
    // admin methods
    // =========================

    /// @notice Sets the address of the fee contract.
    function setFeeContractAddress(address feeContractAddress) external;

    /// @notice Returns the address of the fee contract
    function getFeeContractAddress() external view returns (address feeContractAddress);

    // =========================
    // diamond getters
    // =========================

    // These functions are expected to be called frequently by tools

    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return _facets Facet
    function facets() external view returns (Facet[] memory _facets);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param facet The facet address.
    /// @return _facetFunctionSelectors
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory _facetFunctionSelectors);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return _facets
    function facetAddresses() external view returns (address[] memory _facets);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param functionSelector The function selector.
    /// @return _facet The facet address.
    function facetAddress(bytes4 functionSelector) external view returns (address _facet);
}
