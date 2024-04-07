// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { MultiswapRouter, IMultiswapRouter } from "../src/MultiswapRouter.sol";
import { Proxy } from "../src/proxy/Proxy.sol";

contract MultiswapRouterDeploy is Script {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        new Proxy(
            address(new MultiswapRouter()),
            abi.encodeCall(
                IMultiswapRouter.initialize,
                (
                    300, /* insert your protocolFee */
                    IMultiswapRouter.ReferralFee({ protocolPart: 200, referralPart: 50 }), /* insert your referralFee */
                    deployer
                )
            )
        );

        vm.stopBroadcast();
    }
}
