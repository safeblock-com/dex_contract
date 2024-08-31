// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";
import { DeployEngine, Contracts, getContracts } from "../../script/DeployEngine.sol";

import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";

import { IEntryPoint } from "../../src/EntryPoint.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { StargateFacet, IStargateFacet, IStargateComposer } from "../../src/facets/bridges/StargateFacet.sol";
import { LayerZeroFacet, UlnConfig } from "../../src/facets/bridges/LayerZeroFacet.sol";
import { TransferHelper } from "../../src/facets/libraries/TransferHelper.sol";

import "../Helpers.t.sol";

contract LayerZeroFacetTest is Test {
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

        LayerZeroFacet(address(bridge)).setDefaultGasLimit(50_000);
        LayerZeroFacet(address(bridge)).setDelegate(owner);

        vm.stopPrank();
    }

    // =========================
    // getters and setters
    // =========================

    function test_layerZeroFacet_gettersAndSetters() external {
        new LayerZeroFacet(contracts.endpointV2);

        assertEq(LayerZeroFacet(address(bridge)).eid(), 30_102);

        assertEq(LayerZeroFacet(address(bridge)).defaultGasLimit(), 50_000);

        hoax(owner);
        LayerZeroFacet(address(bridge)).setDefaultGasLimit(100_000);
        assertEq(LayerZeroFacet(address(bridge)).defaultGasLimit(), 100_000);

        assertTrue(LayerZeroFacet(address(bridge)).isSupportedEid(30_101));
        assertEq(LayerZeroFacet(address(bridge)).getPeer(30_101), bytes32(uint256(uint160(address(bridge)))));

        hoax(owner);
        LayerZeroFacet(address(bridge)).setPeers(
            Solarray.uint32s(30_101), Solarray.bytes32s(bytes32(uint256(uint160(owner))))
        );
        assertEq(LayerZeroFacet(address(bridge)).getPeer(30_101), bytes32(uint256(uint160(owner))));

        assertEq(LayerZeroFacet(address(bridge)).getDelegate(), owner);

        hoax(owner);
        LayerZeroFacet(address(bridge)).setDelegate(address(this));
        assertEq(LayerZeroFacet(address(bridge)).getDelegate(), address(this));

        assertEq(LayerZeroFacet(address(bridge)).getGasLimit(30_101), 100_000);

        hoax(owner);
        LayerZeroFacet(address(bridge)).setGasLimit(Solarray.uint32s(30_101), Solarray.uint128s(30_000));
        assertEq(LayerZeroFacet(address(bridge)).getGasLimit(30_101), 30_000);

        assertEq(LayerZeroFacet(address(bridge)).getNativeSendCap(30_101), 0.24e18);

        assertTrue(LayerZeroFacet(address(bridge)).isSupportedEid(30_101));
    }

    // =========================
    // sendDeposit
    // =========================

    uint32 dstEidV2 = 30_101;
    address stargatePool = 0x138EB30f73BC423c6455C53df6D89CB01d9eBc63;

    function test_layerZeroFacet_sendDeposit_shoudSendDeposit() external {
        uint128 nativeTransferCap = LayerZeroFacet(address(bridge)).getNativeSendCap(dstEidV2);

        uint256 fee = LayerZeroFacet(address(bridge)).estimateFee(dstEidV2, nativeTransferCap, address(0));

        deal(USDT, user, 1000e18);

        startHoax(user);

        IERC20(USDT).approve(address(bridge), 1000e18);

        (uint256 _fee,) = StargateFacet(address(bridge)).quoteV2(stargatePool, dstEidV2, 1000e18, user, bytes(""), 0);

        bridge.multicall{ value: fee + _fee }(
            Solarray.bytess(
                abi.encodeCall(StargateFacet.sendStargateV2, (stargatePool, dstEidV2, 1000e18, user, 0, bytes(""))),
                abi.encodeCall(LayerZeroFacet.sendDeposit, (dstEidV2, nativeTransferCap, address(0)))
            )
        );

        vm.stopPrank();
    }
}
