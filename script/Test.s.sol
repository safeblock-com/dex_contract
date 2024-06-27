// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { StargateFacet, MessagingFee } from "../src/facets/bridges/StargateFacet.sol";

contract Tst is Script {
    address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    StargateFacet stargate = StargateFacet(0x387f7c5A79bCb3B5C281c505b39fd48Cec0B814C);

    // sepolia
    address stargateNativePool = 0xa5A8481790BB57CF3FA0a4f24Dc28121A491447f;
    address stargateUSDTPool = 0xc9c7A3Ae8F1059867247a009b32Ad7AAD9a52D1c;
    address USDT = 0xB15a3F6E64D2CaffAF7927431AB0D1c21e429644; // 18 decimals

    // arb
    address arbStargateNativePool = 0x0a0C1221f451Ac54Ef9F21940569E252161a2495;

    // bnb
    address bnbStargateUSDTPool = 0x0a0C1221f451Ac54Ef9F21940569E252161a2495;
    address bnbUSDT = 0xe37Bdc6F09DAB6ce6E4eBC4d2E72792994Ef3765; // 6 decimals

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        (,,,MessagingFee memory fee) =stargate.prepareTransferAndCall(
            bnbStargateUSDTPool,
            40_161,
            384200,
            address(stargate),
            abi.encode(
                USDT,
                deployer,
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000044),
                abi.encodeCall(TransferFacet.transfer, (address(USDT), address(deployer), 0))
            ),
            350_000
        );

        IERC20(bnbUSDT).approve(address(stargate), 384200);

        stargate.sendStargate{value:fee.nativeFee}(
            bnbStargateUSDTPool,
            40_161,
            384200,
            address(stargate),
            350_000,
            abi.encode(
                USDT,
                deployer,
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000044),
                abi.encodeCall(TransferFacet.transfer, (address(USDT), address(deployer), 0))
            ),
            deployer
        );
    }
}
