// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferHelper } from "./TransferHelper.sol";
import { FEE_CONTRACT_STORAGE, E6, ADDRESS_MASK } from "./Constants.sol";

/// @title FeeLibrary
/// @notice Library for managing and paying protocol fees in a diamond-like proxy contract.
/// @dev Handles storage and payment of protocol fees using assembly for efficient storage operations.
///      This library is used throughout the protocol to handle fee calculations and transfers.
library FeeLibrary {
    // =========================
    // functions
    // =========================

    /// @notice Sets the fee contract address and fee amount into storage.
    /// @dev Packs the fee and address into a single 256-bit word and stores it in `FEE_CONTRACT_STORAGE`.
    ///      The fee is left-shifted by 160 bits, and the address occupies the lower 160 bits.
    /// @param feeContractAddress The address that will receive the protocol fee.
    /// @param fee The protocol fee, scaled relative to `E6` (e.g. 2500 = 0.25% if E6 = 1e6).
    function setFeeContractAddress(address feeContractAddress, uint256 fee) internal {
        assembly ("memory-safe") {
            sstore(FEE_CONTRACT_STORAGE, add(shl(160, fee), feeContractAddress))
        }
    }

    /// @notice Retrieves the fee contract address and fee amount from storage.
    /// @dev Unpacks the 256-bit storage word into fee (upper 96 bits) and address (lower 160 bits).
    /// @return feeContractAddress The stored address to which protocol fees are sent.
    /// @return fee The stored protocol fee, scaled relative to `E6`.
    function getFeeContractAddress() internal view returns (address feeContractAddress, uint256 fee) {
        assembly ("memory-safe") {
            feeContractAddress := sload(FEE_CONTRACT_STORAGE)
            fee := shr(160, feeContractAddress)
            feeContractAddress := and(feeContractAddress, ADDRESS_MASK)
        }
    }

    /// @notice Transfers protocol fee to the fee contract, if fee is set and greater than zero.
    /// @dev Fee is calculated as `(amount * fee) / E6`. Uses `TransferHelper.safeTransfer`.
    /// @param feeContract Address of the contract receiving the fee.
    /// @param fee The protocol fee, scaled relative to `E6`.
    /// @param token The token being transferred.
    /// @param amount The total amount before fee deduction.
    /// @return feeAmount The actual amount transferred as protocol fee.
    function payFee(
        address feeContract,
        uint256 fee,
        address token,
        uint256 amount
    )
        internal
        returns (uint256 feeAmount)
    {
        if (feeContract > address(0)) {
            unchecked {
                feeAmount = amount * fee / E6;
                if (feeAmount > 0) {
                    TransferHelper.safeTransfer({ token: token, to: feeContract, value: feeAmount });
                }
            }
        }
    }
}
