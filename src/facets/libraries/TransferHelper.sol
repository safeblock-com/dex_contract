// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

/// @title TransferHelper
/// @notice A helper library for safe transfers, approvals, and balance checks.
/// @dev Provides safe functions for ERC20 token and native currency transfers.
library TransferHelper {
    // =========================
    // errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_TransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_TransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_ApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_GetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_TransferNativeError();

    // =========================
    // functions
    // =========================

    /// @notice Executes a safe transfer from one address to another.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferFrom(address token, address from, uint256 value, address to) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transferFrom, (from, to, value)))) {
            revert TransferHelper_TransferFromError();
        }
    }

    /// @notice Executes a safe transfer.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransfer(address token, address to, uint256 value) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transfer, (to, value)))) {
            revert TransferHelper_TransferError();
        }
    }

    /// @notice Executes a safe approval.
    /// @dev Uses low-level calls to handle cases where allowance is not zero
    /// and tokens which are not supports approve with non-zero allowance.
    /// @param token Address of the ERC20 token to approve.
    /// @param spender Address of the account that gets the approval.
    /// @param value Amount to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(IERC20.approve, (spender, value));

        if (!_makeCall(token, approvalCall)) {
            if (!_makeCall(token, abi.encodeCall(IERC20.approve, (spender, 0))) || !_makeCall(token, approvalCall)) {
                revert TransferHelper_ApproveError();
            }
        }
    }

    /// @notice Retrieves the balance of an account safely.
    /// @dev Uses low-level staticcall to ensure proper error handling.
    /// @param token Address of the ERC20 token.
    /// @param account Address of the account to fetch balance for.
    /// @return The balance of the account.
    function safeGetBalance(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
        if (!success || data.length == 0) {
            revert TransferHelper_GetBalanceError();
        }
        return abi.decode(data, (uint256));
    }

    /// @notice Executes a safe transfer of native currency (e.g., ETH).
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferNative(address to, uint256 value) internal {
        assembly ("memory-safe") {
            if iszero(call(gas(), to, value, 0, 0, 0, 0)) {
                // revert TransferHelper_TransferNativeError();
                mstore(0, 0xb1a0fdf8)
                revert(28, 4)
            }

            // send anonymous event with the `to` address
            mstore(0, to)
            log0(0, 32)
        }
    }

    // =========================
    // private function
    // =========================

    /// @dev Helper function to make a low-level call for token methods.
    /// @dev Ensures correct return value and decodes it.
    ///
    /// @param token Address to make the call on.
    /// @param data Calldata for the low-level call.
    /// @return True if the call succeeded, false otherwise.
    function _makeCall(address token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returnData) = token.call(data);
        return success && (returnData.length == 0 || abi.decode(returnData, (bool)));
    }
}
