// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/bridges/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/bridges/LayerZeroFacet.sol";
import { SymbiosisFacet } from "../src/facets/bridges/SymbiosisFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address transferFacet;
    address multiswapRouterFacet;
    address stargateFacet;
    address layerZeroFacet;
    address symbiosisFacet;
    //
    address quoter;
    address quoterProxy;
    address proxy;
    address feeContract;
    address feeContractProxy;
    address prodFeeContractProxy;
    //
    address prodEntryPoint;
    address prodProxy;
    //
    address wrappedNative;
    address layerZeroEndpointV2;
    address symbiosisPortal;
    address permit2;
    //
    address multisig;
}

address constant multisig = address(1);

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            transferFacet: address(0),
            multiswapRouterFacet: address(0),
            stargateFacet: address(0),
            layerZeroFacet: address(0),
            symbiosisFacet: address(1),
            //
            quoter: address(0),
            quoterProxy: address(0),
            proxy: address(0),
            feeContract: address(0),
            feeContractProxy: address(0),
            //
            prodEntryPoint: address(0),
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            transferFacet: 0x605750a4e1d8971d64a7c4FD5f8DF238e06dFFc6,
            multiswapRouterFacet: 0x4b6FeDf62D61A5276e4CAf9853Ea70989cDDc967,
            stargateFacet: 0xdd4ec4bFecAb02CbE60CdBA8De49821a1105c24f,
            layerZeroFacet: 0xC2F6a6c1712899fCA57df645cfA0E9d04e0B5A38,
            symbiosisFacet: address(1),
            //
            quoter: 0x2ef78f53965cB6b6BE3DF79e143D07790c3E84b3,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0xA41be65A7C167D401F8bD980ebb019AF5a7bfe26,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            prodEntryPoint: 0xC40D56c2cb35E7d0d4c1a5C313500C144b8f5AAD,
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            transferFacet: 0x962056fe62f32B3C823e2E6B150bF142af26d93A,
            multiswapRouterFacet: 0xf145B88a658AAf85A7169caC1769a389675a073A,
            stargateFacet: 0x40EC78B5A9170b66Aa12B17627A97429f596a185,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            symbiosisFacet: address(1),
            //
            quoter: 0x33E3337E3d68aB3b56C86613CCF34CB0d006Ab04,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            prodEntryPoint: 0xDF1B257a5A188132ECFaB846d5E9c67Bc17aDA73,
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Contracts({
            transferFacet: 0x453B60E247108B92C3B413bF944853A43da9b850,
            multiswapRouterFacet: 0xf145B88a658AAf85A7169caC1769a389675a073A,
            stargateFacet: 0x40EC78B5A9170b66Aa12B17627A97429f596a185,
            layerZeroFacet: 0xC0D032E84682c43e101E1e6578E0dEded5d224eD,
            symbiosisFacet: address(1),
            //
            quoter: 0x33E3337E3d68aB3b56C86613CCF34CB0d006Ab04,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x861fF1De5877d91ebE37cE8fB95274524f5f8E21,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            prodEntryPoint: 0x4bb53eBbBbAC038248aC3983fF9242Fa76a39C12,
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xE75C7E85FE6ADd07077467064aD15847E6ba9877,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // optimism
    if (chainId == 10) {
        return Contracts({
            transferFacet: 0x0BF76A83c92AAc1214C7F256A923863a37c40FBe,
            multiswapRouterFacet: 0x7559382f22a50e22d5c6026E04be5cd73Bcfa4c4,
            stargateFacet: 0x6bF6c75738dC7114E162fB4df10ABADCF1b5bDb0,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            symbiosisFacet: address(1),
            //
            quoter: 0x033D438b5a95216740F14e80b6Ce045C0E65d610,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            prodEntryPoint: 0x4b6FeDf62D61A5276e4CAf9853Ea70989cDDc967,
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Contracts({
            transferFacet: 0x0BF76A83c92AAc1214C7F256A923863a37c40FBe,
            multiswapRouterFacet: 0x7559382f22a50e22d5c6026E04be5cd73Bcfa4c4,
            stargateFacet: 0x6bF6c75738dC7114E162fB4df10ABADCF1b5bDb0,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            symbiosisFacet: address(1),
            //
            quoter: 0x033D438b5a95216740F14e80b6Ce045C0E65d610,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            prodEntryPoint: 0x4b6FeDf62D61A5276e4CAf9853Ea70989cDDc967,
            prodProxy: address(0),
            prodFeeContractProxy: address(0),
            //
            wrappedNative: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x01A3c8E513B758EBB011F7AFaf6C37616c9C24d9,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    Contracts memory c;
    return c;
}

library DeployEngine {
    function deployEntryPoint(Contracts memory contracts) internal returns (address) {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory facetAddresses = new address[](25);
        uint256[] memory addressIndexes = new uint256[](250);

        uint256 i;
        uint256 j;
        uint256 addressIndex;

        if (contracts.transferFacet != address(0)) {
            // transfer Facet
            selectors[i++] = TransferFacet.getNonceForPermit2.selector;
            selectors[i++] = TransferFacet.transferFromPermit2.selector;
            selectors[i++] = TransferFacet.transferToken.selector;
            selectors[i++] = TransferFacet.transferNative.selector;
            selectors[i++] = TransferFacet.unwrapNative.selector;
            selectors[i++] = TransferFacet.unwrapNativeAndTransferTo.selector;
            for (uint256 k; k < 6; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            facetAddresses[addressIndex] = contracts.transferFacet;
            ++addressIndex;
        }

        if (contracts.multiswapRouterFacet != address(0)) {
            // multiswap Facet
            selectors[i++] = MultiswapRouterFacet.wrappedNative.selector;
            selectors[i++] = MultiswapRouterFacet.feeContract.selector;
            selectors[i++] = MultiswapRouterFacet.setFeeContract.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap.selector;
            selectors[i++] = MultiswapRouterFacet.partswap.selector;
            for (uint256 k; k < 5; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            facetAddresses[addressIndex] = contracts.multiswapRouterFacet;
            ++addressIndex;
        }

        if (contracts.stargateFacet != address(0)) {
            selectors[i++] = StargateFacet.lzEndpoint.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < 4; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            facetAddresses[addressIndex] = contracts.stargateFacet;
            ++addressIndex;
        }

        if (contracts.layerZeroFacet != address(0)) {
            selectors[i++] = LayerZeroFacet.eid.selector;
            selectors[i++] = LayerZeroFacet.defaultGasLimit.selector;
            selectors[i++] = LayerZeroFacet.getPeer.selector;
            selectors[i++] = LayerZeroFacet.getGasLimit.selector;
            selectors[i++] = LayerZeroFacet.getDelegate.selector;
            selectors[i++] = LayerZeroFacet.getUlnConfig.selector;
            selectors[i++] = LayerZeroFacet.getNativeSendCap.selector;
            selectors[i++] = LayerZeroFacet.isSupportedEid.selector;
            selectors[i++] = LayerZeroFacet.estimateFee.selector;
            selectors[i++] = LayerZeroFacet.sendDeposit.selector;
            selectors[i++] = LayerZeroFacet.setPeers.selector;
            selectors[i++] = LayerZeroFacet.setGasLimit.selector;
            selectors[i++] = LayerZeroFacet.setDefaultGasLimit.selector;
            selectors[i++] = LayerZeroFacet.setDelegate.selector;
            selectors[i++] = LayerZeroFacet.setUlnConfigs.selector;
            selectors[i++] = LayerZeroFacet.nextNonce.selector;
            selectors[i++] = LayerZeroFacet.allowInitializePath.selector;
            selectors[i++] = LayerZeroFacet.lzReceive.selector;
            for (uint256 k; k < 18; ++k) {
                addressIndexes[j++] = addressIndex;
            }

            facetAddresses[addressIndex] = contracts.layerZeroFacet;

            ++addressIndex;
        }

        if (contracts.symbiosisFacet > address(1)) {
            selectors[i++] = SymbiosisFacet.portal.selector;
            selectors[i++] = SymbiosisFacet.send.selector;
            for (uint256 k; k < 2; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            facetAddresses[addressIndex] = contracts.symbiosisFacet;
            ++addressIndex;
        }

        assembly {
            mstore(selectors, i)
            mstore(addressIndexes, j)
            mstore(facetAddresses, addressIndex)
        }

        return address(
            new EntryPoint({
                facetsAndSelectors: getBytesArray({
                    selectors: selectors,
                    addressIndexes: addressIndexes,
                    facetAddresses: facetAddresses
                })
            })
        );
    }

    function deployImplemetations(
        Contracts memory contracts,
        bool isTest
    )
        internal
        returns (Contracts memory, bool upgrade)
    {
        if (contracts.multiswapRouterFacet == address(0) || isTest) {
            upgrade = true;

            contracts.multiswapRouterFacet =
                address(new MultiswapRouterFacet({ wrappedNative_: contracts.wrappedNative }));
        }

        if (contracts.transferFacet == address(0) || isTest) {
            upgrade = true;

            contracts.transferFacet =
                address(new TransferFacet({ wrappedNative: contracts.wrappedNative, permit2: contracts.permit2 }));
        }

        if (contracts.stargateFacet == address(0) || isTest) {
            upgrade = true;

            contracts.stargateFacet = address(new StargateFacet({ endpointV2: contracts.layerZeroEndpointV2 }));
        }

        if (contracts.layerZeroFacet == address(0) || isTest) {
            upgrade = true;

            contracts.layerZeroFacet = address(new LayerZeroFacet({ endpointV2: contracts.layerZeroEndpointV2 }));
        }

        if (contracts.symbiosisFacet == address(0) || isTest) {
            upgrade = true;

            contracts.symbiosisFacet = address(new SymbiosisFacet({ portal_: contracts.symbiosisPortal }));
        }

        return (contracts, upgrade);
    }

    function getBytesArray(
        bytes4[] memory selectors,
        uint256[] memory addressIndexes,
        address[] memory facetAddresses
    )
        internal
        pure
        returns (bytes memory logicsAndSelectors)
    {
        quickSort(selectors, addressIndexes);

        uint256 selectorsLength = selectors.length;
        if (selectorsLength != addressIndexes.length) {
            revert("length of selectors and addressIndexes must be equal");
        }

        if (selectorsLength > 0) {
            uint256 length;

            unchecked {
                length = selectorsLength - 1;
            }

            // check that the selectors are sorted and there's no repeating
            for (uint256 i; i < length;) {
                unchecked {
                    if (selectors[i] >= selectors[i + 1]) {
                        revert("selectors must be sorted and there's no repeating");
                    }

                    ++i;
                }
            }
        }

        uint256 addressesLength = facetAddresses.length;
        unchecked {
            logicsAndSelectors = new bytes(4 + selectorsLength * 5 + addressesLength * 20);
        }

        assembly ("memory-safe") {
            let selectorAndAddressIndexValue
            // offset in memory to the beginning of selectors array values
            selectors := add(selectors, 32)
            // offset in memory to beginning of addressIndexes array values
            addressIndexes := add(addressIndexes, 32)
            // offset in memory to beginning of logicsAndSelectors bytes
            let logicsAndSelectorsOffset := add(logicsAndSelectors, 32)

            // write metadata -> selectors array length and addresses offset
            mstore(logicsAndSelectorsOffset, shl(224, add(shl(16, selectorsLength), mul(selectorsLength, 5))))
            logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 4)

            for { } selectorsLength {
                // post actions
                selectorsLength := sub(selectorsLength, 1)
                selectors := add(selectors, 32)
                addressIndexes := add(addressIndexes, 32)
                logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 5)
            } {
                // value creation:
                // 0xaaaaaaaaff000000000000000000000000000000000000000000000000000000
                selectorAndAddressIndexValue := or(mload(selectors), shl(216, mload(addressIndexes)))
                // store the value in the logicsAndSelectors byte array
                mstore(logicsAndSelectorsOffset, selectorAndAddressIndexValue)
            }

            for {
                // offset in memory to the beginning of facetAddresses array values
                facetAddresses := add(facetAddresses, 32)
            } addressesLength {
                // post actions
                addressesLength := sub(addressesLength, 1)
                facetAddresses := add(facetAddresses, 32)
                logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 20)
            } {
                // store the address in the logicsAndSelectors byte array
                mstore(logicsAndSelectorsOffset, shl(96, mload(facetAddresses)))
            }
        }
    }

    function quickSort(bytes4[] memory selectors, uint256[] memory addressIndexes) internal pure {
        if (selectors.length <= 1) {
            return;
        }

        int256 low;
        int256 high = int256(selectors.length - 1);
        int256[] memory stack = new int256[](selectors.length);
        int256 top = -1;

        ++top;
        stack[uint256(top)] = low;
        ++top;
        stack[uint256(top)] = high;

        while (top >= 0) {
            high = stack[uint256(top)];
            --top;
            low = stack[uint256(top)];
            --top;

            int256 pivotIndex = _partition(selectors, addressIndexes, low, high);

            if (pivotIndex - 1 > low) {
                ++top;
                stack[uint256(top)] = low;
                ++top;
                stack[uint256(top)] = pivotIndex - 1;
            }

            if (pivotIndex + 1 < high) {
                ++top;
                stack[uint256(top)] = pivotIndex + 1;
                ++top;
                stack[uint256(top)] = high;
            }
        }
    }

    function _partition(
        bytes4[] memory selectors,
        uint256[] memory addressIndexes,
        int256 low,
        int256 high
    )
        internal
        pure
        returns (int256)
    {
        bytes4 pivot = selectors[uint256(high)];
        int256 i = low - 1;

        for (int256 j = low; j < high; ++j) {
            if (selectors[uint256(j)] <= pivot) {
                i++;
                (selectors[uint256(i)], selectors[uint256(j)]) = (selectors[uint256(j)], selectors[uint256(i)]);

                if (addressIndexes.length == selectors.length) {
                    (addressIndexes[uint256(i)], addressIndexes[uint256(j)]) =
                        (addressIndexes[uint256(j)], addressIndexes[uint256(i)]);
                }
            }
        }

        (selectors[uint256(i + 1)], selectors[uint256(high)]) = (selectors[uint256(high)], selectors[uint256(i + 1)]);

        if (addressIndexes.length == selectors.length) {
            (addressIndexes[uint256(i + 1)], addressIndexes[uint256(high)]) =
                (addressIndexes[uint256(high)], addressIndexes[uint256(i + 1)]);
        }

        return i + 1;
    }
}
