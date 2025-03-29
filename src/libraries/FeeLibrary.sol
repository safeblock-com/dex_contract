// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferHelper } from "../facets/libraries/TransferHelper.sol";
import { TransientStorageFacetLibrary } from "./TransientStorageFacetLibrary.sol";

import { FEE_CONTRACT_STORAGE, FEE_MAX, ADDRESS_MASK } from "./Constants.sol";

/// @title FeeLibrary
/// @dev library for store and pay protocol fee
library FeeLibrary {
    /// @notice set fee contract address
    function setFeeContractAddress(address feeContractAddress, uint256 fee) internal {
        assembly ("memory-safe") {
            sstore(FEE_CONTRACT_STORAGE, add(shl(160, fee), feeContractAddress))
        }
    }

    /// @notice get fee contract address
    function getFeeContractAddress() internal view returns (address feeContractAddress, uint256 fee) {
        assembly ("memory-safe") {
            feeContractAddress := sload(FEE_CONTRACT_STORAGE)
            fee := shr(160, feeContractAddress)
            feeContractAddress := and(feeContractAddress, ADDRESS_MASK)
        }
    }

    /// @notice pay protocol fee
    function payFee(address token, uint256 amount) internal returns (uint256) {
        if (!TransientStorageFacetLibrary.isFeePaid()) {
            (address feeContract, uint256 fee) = getFeeContractAddress();
            if (feeContract > address(0) && fee > 0) {
                unchecked {
                    fee = amount * fee / FEE_MAX;

                    if (fee > 0) {
                        TransferHelper.safeTransfer({ token: token, to: feeContract, value: fee });
                        return amount - fee;
                    }
                }
            }
        }

        return amount;
    }
}
