// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeContract - FeeContract interface
interface IFeeContract {
    // =========================
    // errors
    // =========================

    /// @dev Throws if `fee` is invalid
    error FeeContract_InvalidFeeValue();

    /// @dev Throws if `sender` is not the router
    error FeeContract_InvalidSender(address sender);

    // =========================
    // getters
    // =========================

    /// @notice Returns router address
    function router() external view returns (address);

    /// @notice Returns the balance of the `owner` for the `token`
    function profit(address owner, address token) external view returns (uint256 balance);

    /// @notice Returns the protocol fee
    function fees() external view returns (uint256 protocolFee);

    // =========================
    // admin logic
    // =========================

    /// @notice Sets new router
    function setRouter(address newRouter) external;

    /// @notice Sets new protocol fee
    function setProtocolFee(uint256 newProtocolFee) external;

    // =========================
    // fees logic
    // =========================

    /// @notice Collects protocol fees
    function collectProtocolFees(address token, address recipient, uint256 amount) external;

    /// @notice Writes fees for the token
    function writeFees(address token, uint256 amount) external returns (uint256);
}
