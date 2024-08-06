// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { EntryPoint } from "../../src/EntryPoint.sol";
import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";
import { MultiswapRouterFacet } from "../../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { StargateFacet } from "../../src/facets/bridges/StargateFacet.sol";

import { DeployEngine } from "../DeployEngine.sol";

contract Deploy is Script {
    address multiswapRouterFacet = 0xFC08aCb8ab29159Cc864D7c7EC8AF2b611DE0820;
    address transferFacet = 0xd41B295F9695c3E90e845918aBB384D73a85C635;

    address stargateFacet = 0xB5fEB7A7241058509655F18246e2C9cd10B39626;

    address proxy = 0x29F4Bf32E90cAcb299fC82569670f670d334630a;

    bool upgrade;

    // ===================
    // helpers for multiswapFacet and transferFacet deployment
    // ===================

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    // ===================
    // helpers for stargateFacet deployment
    // ===================

    // bnb testnet
    address endpointV2 = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address stargateComposerV1 = 0x75D573607f5047C728D3a786BE3Ba33765712875;

    // ===================

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        _deployImplemetations();

        if (upgrade) {
            address entryPoint = DeployEntryPoint.deployEntryPoint(transferFacet, multiswapRouterFacet, stargateFacet);

            if (proxy == address(0)) {
                proxy = address(new Proxy(deployer));

                bytes[] memory initCalls = new bytes[](0);

                InitialImplementation(proxy).upgradeTo(
                    entryPoint, abi.encodeCall(EntryPoint.initialize, (deployer, initCalls))
                );
            } else {
                EntryPoint(payable(proxy)).upgradeTo(entryPoint);
            }
        }

        vm.stopBroadcast();
    }

    function _deployImplemetations() internal {
        if (multiswapRouterFacet == address(0)) {
            upgrade = true;

            multiswapRouterFacet = address(new MultiswapRouterFacet(WBNB));
        }

        if (transferFacet == address(0)) {
            upgrade = true;

            transferFacet = address(new TransferFacet(WBNB));
        }

        if (stargateFacet == address(0)) {
            upgrade = true;

            stargateFacet = address(new StargateFacet(endpointV2, stargateComposerV1));
        }
    }
}

library DeployEntryPoint {
    function deployEntryPoint(
        address transferFacet,
        address multiswapRouterFacet,
        address stargateFacet
    )
        internal
        returns (address)
    {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory facetAddresses = new address[](250);

        uint256 i;
        uint256 j;

        if (transferFacet != address(0)) {
            // transfer Facet
            selectors[i++] = TransferFacet.transferToken.selector;
            selectors[i++] = TransferFacet.transferNative.selector;
            selectors[i++] = TransferFacet.unwrapNative.selector;
            selectors[i++] = TransferFacet.unwrapNativeAndTransferTo.selector;
            for (uint256 k; k < 4; ++k) {
                facetAddresses[j++] = transferFacet;
            }
        }

        if (multiswapRouterFacet != address(0)) {
            // multiswap Facet
            selectors[i++] = MultiswapRouterFacet.wrappedNative.selector;
            selectors[i++] = MultiswapRouterFacet.feeContract.selector;
            selectors[i++] = MultiswapRouterFacet.setFeeContract.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap.selector;
            selectors[i++] = MultiswapRouterFacet.partswap.selector;
            for (uint256 k; k < 5; ++k) {
                facetAddresses[j++] = multiswapRouterFacet;
            }
        }

        if (stargateFacet != address(0)) {
            selectors[i++] = StargateFacet.lzEndpoint.selector;
            selectors[i++] = StargateFacet.stargateV1Composer.selector;
            selectors[i++] = StargateFacet.quoteV1.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV1.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.sgReceive.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < 8; ++k) {
                facetAddresses[j++] = stargateFacet;
            }
        }

        assembly {
            mstore(selectors, i)
            mstore(facetAddresses, j)
        }

        return address(new EntryPoint(DeployEngine.getBytesArray(selectors, facetAddresses)));
    }
}
