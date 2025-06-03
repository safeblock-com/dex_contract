// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferHelper } from "../facets/libraries/TransferHelper.sol";
import { TransientStorageFacetLibrary } from "./TransientStorageFacetLibrary.sol";

import { FEE_CONTRACT_STORAGE, FEE_MAX, ADDRESS_MASK } from "./Constants.sol";

/// @title FeeLibrary
/// @notice Library for managing and paying protocol fees in a diamond-like proxy contract.
/// @dev Handles storage and payment of protocol fees using assembly for efficient storage operations.
library FeeLibrary {
    // =========================
    // functions
    // =========================

    /// @dev Sets the fee contract address and fee amount in transient storage.
    ///      Stores the fee and address in the `FEE_CONTRACT_STORAGE` slot, combining them into a single word.
    /// @param feeContractAddress The address of the fee contract.
    /// @param fee The fee amount to set, scaled relative to `FEE_MAX`.
    function setFeeContractAddress(address feeContractAddress, uint256 fee) internal {
        assembly ("memory-safe") {
            sstore(FEE_CONTRACT_STORAGE, add(shl(160, fee), feeContractAddress))
        }
    }

    /// @dev Retrieves the fee contract address and fee amount from transient storage.
    ///      Reads from the `FEE_CONTRACT_STORAGE` slot, extracting the fee and address using bitwise operations.
    /// @return feeContractAddress The address of the fee contract.
    /// @return fee The current fee amount, scaled relative to `FEE_MAX`.
    function getFeeContractAddress() internal view returns (address feeContractAddress, uint256 fee) {
        assembly ("memory-safe") {
            feeContractAddress := sload(FEE_CONTRACT_STORAGE)
            fee := shr(160, feeContractAddress)
            feeContractAddress := and(feeContractAddress, ADDRESS_MASK)
        }
    }

    /// @dev Pays the protocol fee for a token transfer if applicable.
    ///      Checks if the fee is unpaid using `TransientStorageFacetLibrary.isFeePaid`.
    ///      If a fee is configured, calculates and transfers the fee using `TransferHelper`.
    ///      Returns the remaining amount after fee deduction.
    /// @param token The address of the token to transfer.
    /// @param amount The total amount of the token before fee deduction.
    /// @return remainingAmount The amount of the token after deducting the fee, or the original amount if no fee is paid.
    function payFee(address token, uint256 amount, bool exactIn) internal returns (uint256 remainingAmount) {
        if (!TransientStorageFacetLibrary.isFeePaid()) {
            (address feeContract, uint256 fee) = getFeeContractAddress();
            if (feeContract > address(0) && fee > 0) {
                unchecked {
                    fee = amount * fee / FEE_MAX;
                    if (fee > 0) {
                        TransferHelper.safeTransfer({ token: token, to: feeContract, value: fee });

                        if (exactIn) {
                            return amount - fee;
                        } else {
                            return amount + fee;
                        }
                    }
                }
            }
        }
        return amount;
    }
}
