// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { MultiswapRouter } from "../src/MultiswapRouter.sol";

contract MultiswapRouterDeploy is Script {
    MultiswapRouter dex = MultiswapRouter(0xd41B295F9695c3E90e845918aBB384D73a85C635);

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        dex.upgradeTo(address(new MultiswapRouter()));

        vm.stopBroadcast();
    }
}
