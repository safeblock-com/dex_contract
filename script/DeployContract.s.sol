// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { EntryPoint } from "../src/EntryPoint.sol";
import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { MultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { StargateFacet } from "../src/facets/bridges/StargateFacet.sol";

import { DeployEngine } from "./DeployEngine.sol";

import "../test/Helpers.t.sol";

contract Deploy is Script {
    address multiswapRouterFacet = address(1);
    address transferFacet = address(0);
    address stargateFacet = address(0);

    address proxy = 0x9d5b514435EE72bA227453E907835724Fff6715e;

    bytes32 salt = keccak256("dev_salt-2");

    // testnet
    address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        _deployImplemetations();
        address entryPoint = _deployEntryPoint();

        if (proxy == address(0)) {
            proxy = address(new Proxy{ salt: salt }(deployer));

            InitialImplementation(proxy).upgradeTo(
                entryPoint, abi.encodeCall(EntryPoint.initialize, (deployer, new bytes[](0)))
            );
        } else {
            EntryPoint(payable(proxy)).upgradeTo(entryPoint);
        }

        vm.stopBroadcast();
    }

    function _deployImplemetations() internal {
        if (multiswapRouterFacet == address(0)) {
            multiswapRouterFacet = address(new MultiswapRouterFacet(WBNB));
        }

        if (transferFacet == address(0)) {
            transferFacet = address(new TransferFacet());
        }

        if (stargateFacet == address(0)) {
            stargateFacet = address(new StargateFacet(lzEndpoint));
        }
    }

    function _deployEntryPoint() internal returns (address) {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory facetAddresses = new address[](250);

        uint256 i;
        uint256 j;

        // ERC20 Facet
        selectors[i++] = TransferFacet.transfer.selector;
        selectors[i++] = TransferFacet.transferNative.selector;
        facetAddresses[j++] = transferFacet;
        facetAddresses[j++] = transferFacet;

        if (multiswapRouterFacet != address(1)) {
            // Multiswap Facet
            selectors[i++] = MultiswapRouterFacet.wrappedNative.selector;
            selectors[i++] = MultiswapRouterFacet.feeContract.selector;
            selectors[i++] = MultiswapRouterFacet.setFeeContract.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap.selector;
            selectors[i++] = MultiswapRouterFacet.partswap.selector;
            for (uint256 k; k < 5; ++k) {
                facetAddresses[j++] = multiswapRouterFacet;
            }
        }

        // Stargate Facet
        selectors[i++] = StargateFacet.lzEndpoint.selector;
        selectors[i++] = StargateFacet.prepareTransferAndCall.selector;
        selectors[i++] = StargateFacet.sendStargate.selector;
        selectors[i++] = StargateFacet.lzCompose.selector;
        for (uint256 k; k < 4; ++k) {
            facetAddresses[j++] = stargateFacet;
        }

        assembly {
            mstore(selectors, i)
            mstore(facetAddresses, j)
        }

        return address(new EntryPoint(DeployEngine.getBytesArray(selectors, facetAddresses)));
    }
}
