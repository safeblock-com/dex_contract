// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";

import { EntryPoint } from "../../src/EntryPoint.sol";
import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";
import { MultiswapRouterFacet } from "../../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { StargateFacet, IStargateComposer } from "../../src/facets/bridges/StargateFacet.sol";

import { DeployEngine } from "../DeployEngine.sol";

contract TestnetTestTxs is Script {
    EntryPoint proxy = EntryPoint(payable(0x29F4Bf32E90cAcb299fC82569670f670d334630a));

    // ===================
    // helpers for stargateFacet sends
    // ===================

    // bnb testnet
    address endpointV2 = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address stargateComposerV1 = 0x75D573607f5047C728D3a786BE3Ba33765712875;

    uint16 dstChainIdV1 = 10_161;
    uint256 srcPoolIdV1 = 2;
    uint256 dstPoolIdV1_1 = 1;
    uint256 dstPoolIdV1_2 = 2;

    uint32 dstEidV2 = 40_161;
    address stargatePool = 0x0a0C1221f451Ac54Ef9F21940569E252161a2495;

    IERC20 USDT = IERC20(0xe37Bdc6F09DAB6ce6E4eBC4d2E72792994Ef3765);

    // ===================

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        USDT.approve(address(proxy), 10e6);

        (uint256 fee,) = StargateFacet(address(proxy)).quoteV2(stargatePool, dstEidV2, 10e6, deployer, bytes(""), 0);

        proxy.multicall{ value: fee }(
            Solarray.bytess(
                abi.encodeCall(StargateFacet.sendStargateV2, (stargatePool, dstEidV2, 10e6, deployer, 0, bytes("")))
            )
        );

        vm.stopBroadcast();
    }
}
