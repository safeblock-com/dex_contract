// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPoint - EntryPoint interface
interface IEntryPoint {
    // =========================
    // errors
    // =========================

    /// @notice Throws when the function does not exist in the EntryPoint.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    /// @notice Throws if new `fee` value is invalid
    error EntryPoint_InvalidFeeValue();

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

    // =========================
    // admin methods
    // =========================

    /// @notice Sets the address of the fee contract and the protocol fee.
    function setFeeContractAddressAndFee(address feeContractAddress, uint256 fee) external;

    /// @notice Returns the address of the fee contract and the protocol fee.
    function getFeeContractAddressAndFee() external view returns (address feeContractAddress, uint256 fee);

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
