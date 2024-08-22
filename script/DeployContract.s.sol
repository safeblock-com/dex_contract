// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Quoter } from "../src/lens/Quoter.sol";
import { EntryPoint } from "../src/EntryPoint.sol";

import { InitialImplementation, Proxy } from "../src/proxy/Proxy.sol";

import { DeployEngine, Contracts, getContracts } from "./DeployEngine.sol";

import { LayerZeroFacet } from "../src/facets/bridges/LayerZeroFacet.sol";

contract Deploy is Script {
    bytes32 salt = keccak256("entry-point-salt-1");
    bytes32 quotersalt = keccak256("quoter-salt-1");

    // ===================

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        Contracts memory contracts = getContracts(block.chainid);

        if (contracts.quoter == address(0)) {
            contracts.quoter = address(new Quoter(contracts.wrappedNative));

            if (contracts.quoterProxy == address(0)) {
                contracts.quoterProxy = address(new Proxy{ salt: quotersalt }(deployer));

                InitialImplementation(contracts.quoterProxy).upgradeTo(
                    contracts.quoter, abi.encodeCall(Quoter.initialize, (deployer))
                );
            } else {
                Quoter(contracts.quoterProxy).upgradeTo(contracts.quoter);
            }
        }

        bool upgrade;
        (contracts, upgrade) = DeployEngine.deployImplemetations(contracts, false);

        if (upgrade) {
            address entryPoint = DeployEngine.deployEntryPoint(contracts);

            if (contracts.proxy == address(0)) {
                contracts.proxy = address(new Proxy{ salt: salt }(deployer));

                bytes[] memory initCalls = new bytes[](0);

                InitialImplementation(contracts.proxy).upgradeTo(
                    entryPoint, abi.encodeCall(EntryPoint.initialize, (deployer, initCalls))
                );
            } else {
                EntryPoint(payable(contracts.proxy)).upgradeTo(entryPoint);
            }
        }

        LayerZeroFacet _layerZeroFacet = LayerZeroFacet(contracts.proxy);

        if (_layerZeroFacet.getDelegate() == address(0)) {
            _layerZeroFacet.setDelegate(deployer);
        }
        if (_layerZeroFacet.defaultGasLimit() == 0) {
            _layerZeroFacet.setDefaultGasLimit(50_000);
        }

        vm.stopBroadcast();
    }
}
