// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "./libraries/TransferHelper.sol";

contract ERC20Facet {
    function transfer(address token, address to, uint256 amount) external {
        TransferHelper.safeTransfer({ token: token, to: to, value: amount });
    }
}
