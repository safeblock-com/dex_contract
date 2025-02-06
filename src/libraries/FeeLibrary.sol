// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IFeeContract } from "../interfaces/IFeeContract.sol";
import { TransferHelper } from "../facets/libraries/TransferHelper.sol";
import { TransientStorageFacetLibrary } from "./TransientStorageFacetLibrary.sol";

/// @title FeeLibrary
/// @dev library for store and pay protocol fee
library FeeLibrary {
    // keccak256("feeContract.storage")
    bytes32 internal constant FEE_CONTRACT_STORAGE = 0xde699227b1a7fb52a64c41a77682cef2fe2815e2a233a451b6c9f64b1abac291;

    uint256 private constant FEE_MAX = 1_000_000;

    /// @notice set fee contract address
    function setFeeContractAddress(address feeContractAddress) internal {
        assembly ("memory-safe") {
            sstore(FEE_CONTRACT_STORAGE, feeContractAddress)
        }
    }

    /// @notice get fee contract address
    function getFeeContractAddress() internal view returns (address feeContractAddress) {
        assembly ("memory-safe") {
            feeContractAddress := sload(FEE_CONTRACT_STORAGE)
        }
    }

    /// @notice pay protocol fee
    function payFee(address token, uint256 amount) internal returns (uint256) {
        if (!TransientStorageFacetLibrary.isFeePaid()) {
            address _feeContract = getFeeContractAddress();
            if (_feeContract != address(0)) {
                uint256 fee = IFeeContract(_feeContract).writeFees({ token: token, amount: amount });

                if (fee > 0) {
                    if (token > address(0)) {
                        TransferHelper.safeTransfer({ token: token, to: _feeContract, value: fee });
                    } else {
                        TransferHelper.safeTransferNative({ to: _feeContract, value: fee });
                    }

                    unchecked {
                        return amount - fee;
                    }
                }
            }
        }

        return amount;
    }
}
