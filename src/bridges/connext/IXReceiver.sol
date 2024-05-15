// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXReceiver {
    function xReceive(
        bytes32 transferId,
        uint256 amount,
        address asset,
        address originSender,
        uint32 origin,
        bytes memory callData
    )
        external
        returns (bytes memory);
}
