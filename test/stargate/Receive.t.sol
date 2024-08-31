// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { DeployEngine, Contracts, getContracts } from "../../script/DeployEngine.sol";

import { Solarray } from "solarray/Solarray.sol";

import { InitialImplementation, Proxy } from "../../src/proxy/Proxy.sol";

import { IEntryPoint } from "../../src/EntryPoint.sol";

import { IMultiswapRouterFacet } from "../../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { StargateFacet } from "../../src/facets/bridges/StargateFacet.sol";

import { OFTComposeMsgCodec } from "../../src/facets/bridges/libraries/OFTComposeMsgCodec.sol";

import "../Helpers.t.sol";

contract ReceiveStargateFacetTest is Test {
    IEntryPoint bridge;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    address entryPointImplementation;
    Contracts contracts;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

        contracts = getContracts(56);
        (contracts,) = DeployEngine.deployImplemetations(contracts, true);

        deal(USDT, user, 1000e18);

        startHoax(owner);

        entryPointImplementation = DeployEngine.deployEntryPoint(contracts);

        bridge = IEntryPoint(address(new Proxy(owner)));

        InitialImplementation(address(bridge)).upgradeTo(
            entryPointImplementation, abi.encodeCall(IEntryPoint.initialize, (owner, new bytes[](0)))
        );

        vm.stopPrank();
    }

    // =========================
    // lzCompose
    // =========================

    function test_stargateFacet_laCompose_shouldLzCompose() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 0;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(USDT_USDC_UniV3_100);

        deal(USDT, address(bridge), 995.1e18);

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (USDC, 0, user))
            )
        );

        bytes memory composeMsg =
            abi.encode(USDT, user, 0x00000000000000000000000000000000000000000000000000000000000000e8, multicallData);

        startHoax(contracts.endpointV2);

        StargateFacet(address(bridge)).lzCompose(
            user,
            0x0000000000000000000000000000000000000000000000000000000000240044,
            OFTComposeMsgCodec.encode(
                1, 30_101, 995.1e18, abi.encodePacked(hex"000000000000000000000000", bridge, composeMsg)
            ),
            contracts.endpointV2,
            bytes("")
        );
    }
}
