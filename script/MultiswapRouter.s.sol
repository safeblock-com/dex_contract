// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {MultiswapRouter} from "../src/MultiswapRouter.sol";

contract MultiswapRouterDeploy is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        new MultiswapRouter(
            300, /* insert your protocolFee */
            MultiswapRouter.RefferalFee({protocolPart: 200, refferalPart: 50}) /* insert your referralFee */
        );

        vm.stopBroadcast();
    }
}
