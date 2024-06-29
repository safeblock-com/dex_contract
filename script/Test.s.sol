// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { StargateFacet, MessagingFee } from "../src/facets/bridges/StargateFacet.sol";

import { IStargateComposer } from "../src/facets/bridges/stargate/IStargateComposer.sol";

contract Tst is Script {
    address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    StargateFacet stargate = StargateFacet(0x9d5b514435EE72bA227453E907835724Fff6715e);

    // sepolia
    address stargateNativePool = 0xa5A8481790BB57CF3FA0a4f24Dc28121A491447f;
    address stargateUSDTPool = 0xc9c7A3Ae8F1059867247a009b32Ad7AAD9a52D1c;
    address USDT = 0xB15a3F6E64D2CaffAF7927431AB0D1c21e429644; // 18 decimals

    // arb
    address arbStargateNativePool = 0x1E8A86EcC9dc41106d3834c6F1033D86939B1e0D;

    // bnb
    address bnbStargateUSDTPool = 0x0a0C1221f451Ac54Ef9F21940569E252161a2495;
    address bnbUSDT = 0xe37Bdc6F09DAB6ce6E4eBC4d2E72792994Ef3765; // 6 decimals

    address arbUSDC = 0x3253a335E7bFfB4790Aa4C25C4250d206E9b9773;
    address sepUSDC = 0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590;

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        // V1

        uint256 valueToSend = stargate.quoteV1(
            10_231,
            address(stargate),
            abi.encode(
                deployer,
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000024),
                abi.encodeCall(TransferFacet.transferNative, (deployer, 0))
            ),
            IStargateComposer.lzTxObj({
                // extra gas, if calling smart contract
                dstGasForCall: 150_000,
                // amount of dstChain native currency dropped in destination wallet
                dstNativeAmount: 0,
                // destination wallet for dstChain native currency
                dstNativeAddr: bytes("")
            })
        );

        // IERC20(arbUSDC).approve(address(stargate), 50e6);

        stargate.sendStargateV1{ value: valueToSend + 0.01e18 }(
            10_231,
            13,
            13,
            0.01e18,
            0.005e18,
            address(stargate),
            abi.encode(
                deployer,
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000024),
                abi.encodeCall(TransferFacet.transferNative, (deployer, 0))
            ),
            IStargateComposer.lzTxObj({
                // extra gas, if calling smart contract
                dstGasForCall: 150_000,
                // amount of dstChain native currency dropped in destination wallet
                dstNativeAmount: 0,
                // destination wallet for dstChain native currency
                dstNativeAddr: bytes("")
            })
        );

        // V2

        // uint256 valueToSend = stargate.quoteV2(
        //     stargateNativePool,
        //     40_231,
        //     3_026_000_000_000_000,
        //     address(stargate),
        //     abi.encode(
        //         address(0),
        //         deployer,
        //         bytes32(0x0000000000000000000000000000000000000000000000000000000000000024),
        //         abi.encodeCall(TransferFacet.transferNative, (address(deployer), 0))
        //     ),
        //     350_000
        // );

        // IERC20(bnbUSDT).approve(address(stargate), 384200);

        // stargate.sendStargateV2{ value: valueToSend }(
        // stargateNativePool,
        // 40_231,
        // 3_026_000_000_000_000,
        // address(stargate),
        // 350_000,
        // abi.encode(
        // address(0),
        // deployer,
        // bytes32(0x0000000000000000000000000000000000000000000000000000000000000024),
        // abi.encodeCall(TransferFacet.transferNative, (address(deployer), 0))
        // ),
        // deployer
        // );
    }
}
