// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Quoter } from "../src/lens/Quoter.sol";

import { EntryPoint } from "../src/EntryPoint.sol";
import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { MultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { StargateFacet } from "../src/facets/bridges/StargateFacet.sol";

import { DeployEngine } from "./DeployEngine.sol";

import "../test/Helpers.t.sol";

contract Deploy is Script {
    address quoter = 0x46f4ce97aFd70cd668984C874795941E7Fc591CA;
    address quoterProxy = 0x51a85c557cD6Aa35880D55799849dDCD6c20B5Cd;

    address multiswapRouterFacet = 0x8973bdDC469c0CE56D9b41dA25C4f1b4D0c4DBa9;
    address transferFacet = 0x3BBcB05884ff9b8149E94FcfC7Bd013d18d12D2f;

    address proxy = 0x2Ea84370660448fd9017715f2F36727AE64f5Fe3;

    bool upgrade;

    bytes32 salt = keccak256("entry-point-salt-1");
    bytes32 quotersalt = keccak256("quoter-salt-1");

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        if (quoter == address(0)) {
            quoter = address(new Quoter(WBNB));

            if (quoterProxy == address(0)) {
                quoterProxy = address(new Proxy{ salt: quotersalt }(deployer));

                InitialImplementation(quoterProxy).upgradeTo(quoter, abi.encodeCall(Quoter.initialize, (deployer)));
            } else {
                Quoter(quoterProxy).upgradeTo(quoter);
            }
        }

        _deployImplemetations();

        if (upgrade) {
            address entryPoint = DeployEntryPoint.deployEntryPoint(transferFacet, multiswapRouterFacet);

            if (proxy == address(0)) {
                proxy = address(new Proxy{ salt: salt }(deployer));

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
    }
}

library DeployEntryPoint {
    function deployEntryPoint(address transferFacet, address multiswapRouterFacet) internal returns (address) {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory facetAddresses = new address[](250);

        uint256 i;
        uint256 j;

        if (transferFacet != address(0)) {
            // transfer Facet
            selectors[i++] = TransferFacet.transferToken.selector;
            selectors[i++] = TransferFacet.transferNative.selector;
            selectors[i++] = TransferFacet.unwrapNativeAndTransferTo.selector;
            for (uint256 k; k < 3; ++k) {
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

        // TODO Stargate Facet
        // selectors[i++] = StargateFacet.lzEndpoint.selector;
        // selectors[i++] = StargateFacet.stargateV1Composer.selector;
        // selectors[i++] = StargateFacet.quoteV1.selector;
        // selectors[i++] = StargateFacet.quoteV2.selector;
        // selectors[i++] = StargateFacet.sendStargateV1.selector;
        // selectors[i++] = StargateFacet.sendStargateV2.selector;
        // selectors[i++] = StargateFacet.sgReceive.selector;
        // selectors[i++] = StargateFacet.lzCompose.selector;
        // for (uint256 k; k < 8; ++k) {
        //     facetAddresses[j++] = stargateFacet;
        // }

        assembly {
            mstore(selectors, i)
            mstore(facetAddresses, j)
        }

        return address(new EntryPoint(DeployEngine.getBytesArray(selectors, facetAddresses)));
    }
}
