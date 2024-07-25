// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";
import { DeployEngine } from "../../script/DeployEngine.sol";
import { DeployEntryPoint } from "../../script/DeployContract.s.sol";

import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";

import { IEntryPoint } from "../../src/EntryPoint.sol";
import { MultiswapRouterFacet, IMultiswapRouterFacet } from "../../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { IOwnable } from "../../src/external/IOwnable.sol";

import { Quoter } from "../../src/lens/Quoter.sol";

import "../Helpers.t.sol";

contract PartswapTest is Test {
    MultiswapRouterFacet router;
    Quoter quoter;

    // TODO add later
    // FeeContract feeContract;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    address multiswapRouterFacet;
    address transferFacet;
    address entryPointImplementation;

    function setUp() external {
        vm.createSelectFork(vm.envString("BNB_RPC_URL"));

        startHoax(owner);

        quoter = new Quoter(WBNB);

        multiswapRouterFacet = address(new MultiswapRouterFacet(WBNB));
        transferFacet = address(new TransferFacet(WBNB));

        entryPointImplementation = DeployEntryPoint.deployEntryPoint(transferFacet, multiswapRouterFacet);

        router = MultiswapRouterFacet(address(new Proxy(owner)));

        // TODO add later
        // bytes[] memory initData =
        // Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.setFeeContract, address(feeContract)));

        InitialImplementation(address(router)).upgradeTo(
            entryPointImplementation, abi.encodeCall(IEntryPoint.initialize, (owner, new bytes[](0)))
        );

        vm.stopPrank();
    }
}
