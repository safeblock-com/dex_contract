// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/bridges/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/bridges/LayerZeroFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address transferFacet;
    address multiswapRouterFacet;
    address stargateFacet;
    address layerZeroFacet;
    //
    address quoter;
    address quoterProxy;
    address proxy;
    address feeContract;
    address feeContractProxy;
    //
    address wrappedNative;
    address endpointV2;
}

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            transferFacet: address(0),
            multiswapRouterFacet: address(0),
            stargateFacet: address(0),
            layerZeroFacet: address(0),
            //
            quoter: address(0),
            quoterProxy: address(0),
            proxy: address(0),
            feeContract: address(0),
            feeContractProxy: address(0),
            //
            wrappedNative: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            transferFacet: 0xC0D032E84682c43e101E1e6578E0dEded5d224eD,
            multiswapRouterFacet: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            stargateFacet: 0xdd4ec4bFecAb02CbE60CdBA8De49821a1105c24f,
            layerZeroFacet: 0xC2F6a6c1712899fCA57df645cfA0E9d04e0B5A38,
            //
            quoter: 0xEd02D5A7822d474c21F6e239b81e2ACf1137Ace8,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0xA41be65A7C167D401F8bD980ebb019AF5a7bfe26,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            transferFacet: 0x48229df22D71eecFf545A3698ACbacc5CF41D658,
            multiswapRouterFacet: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            stargateFacet: 0x40EC78B5A9170b66Aa12B17627A97429f596a185,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            //
            quoter: 0xEd02D5A7822d474c21F6e239b81e2ACf1137Ace8,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Contracts({
            transferFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            multiswapRouterFacet: 0x649BC4A713de188d4e68977ad61f9A5AD795D276,
            stargateFacet: 0x40EC78B5A9170b66Aa12B17627A97429f596a185,
            layerZeroFacet: 0xC0D032E84682c43e101E1e6578E0dEded5d224eD,
            //
            quoter: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x861fF1De5877d91ebE37cE8fB95274524f5f8E21,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    // optimism
    if (chainId == 10) {
        return Contracts({
            transferFacet: 0x48229df22D71eecFf545A3698ACbacc5CF41D658,
            multiswapRouterFacet: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            stargateFacet: 0x6bF6c75738dC7114E162fB4df10ABADCF1b5bDb0,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            //
            quoter: 0xEd02D5A7822d474c21F6e239b81e2ACf1137Ace8,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Contracts({
            transferFacet: 0x48229df22D71eecFf545A3698ACbacc5CF41D658,
            multiswapRouterFacet: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            stargateFacet: 0x6bF6c75738dC7114E162fB4df10ABADCF1b5bDb0,
            layerZeroFacet: 0x10255Eb3cd67406b07D6C82E69460848BCa83022,
            //
            quoter: 0xEd02D5A7822d474c21F6e239b81e2ACf1137Ace8,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            feeContract: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            feeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c
        });
    }

    Contracts memory c;
    return c;
}

library DeployEngine {
    function deployEntryPoint(Contracts memory contracts) internal returns (address) {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory facetAddresses = new address[](250);

        uint256 i;
        uint256 j;

        if (contracts.transferFacet != address(0)) {
            // transfer Facet
            selectors[i++] = TransferFacet.transferToken.selector;
            selectors[i++] = TransferFacet.transferNative.selector;
            selectors[i++] = TransferFacet.unwrapNative.selector;
            selectors[i++] = TransferFacet.unwrapNativeAndTransferTo.selector;
            for (uint256 k; k < 4; ++k) {
                facetAddresses[j++] = contracts.transferFacet;
            }
        }

        if (contracts.multiswapRouterFacet != address(0)) {
            // multiswap Facet
            selectors[i++] = MultiswapRouterFacet.wrappedNative.selector;
            selectors[i++] = MultiswapRouterFacet.feeContract.selector;
            selectors[i++] = MultiswapRouterFacet.setFeeContract.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap.selector;
            selectors[i++] = MultiswapRouterFacet.partswap.selector;
            for (uint256 k; k < 5; ++k) {
                facetAddresses[j++] = contracts.multiswapRouterFacet;
            }
        }

        if (contracts.stargateFacet != address(0)) {
            selectors[i++] = StargateFacet.lzEndpoint.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < 4; ++k) {
                facetAddresses[j++] = contracts.stargateFacet;
            }
        }
        // TODO remove duplicates
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
                facetAddresses[j++] = contracts.layerZeroFacet;
            }
        }

        assembly {
            mstore(selectors, i)
            mstore(facetAddresses, j)
        }

        return address(
            new EntryPoint({
                facetsAndSelectors: getBytesArray({ selectors: selectors, facetAddresses: facetAddresses })
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

            contracts.transferFacet = address(new TransferFacet({ wrappedNative: contracts.wrappedNative }));
        }

        if (contracts.stargateFacet == address(0) || isTest) {
            upgrade = true;

            contracts.stargateFacet = address(new StargateFacet({ endpointV2: contracts.endpointV2 }));
        }

        if (contracts.layerZeroFacet == address(0) || isTest) {
            upgrade = true;

            contracts.layerZeroFacet = address(new LayerZeroFacet({ endpointV2: contracts.endpointV2 }));
        }

        return (contracts, upgrade);
    }

    function getBytesArray(
        bytes4[] memory selectors,
        address[] memory facetAddresses
    )
        internal
        pure
        returns (bytes memory logicsAndSelectors)
    {
        quickSort(selectors, facetAddresses);

        uint256 selectorsLength = selectors.length;
        if (selectorsLength != facetAddresses.length) {
            revert("length of selectors and facetAddresses must be equal");
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

        unchecked {
            logicsAndSelectors = new bytes(selectorsLength * 24);
        }

        assembly ("memory-safe") {
            let logicAndSelectorValue
            // counter
            let i
            // offset in memory to the beginning of selectors array values
            let selectorsOffset := add(selectors, 32)
            // offset in memory to beginning of logicsAddresses array values
            let logicsAddressesOffset := add(facetAddresses, 32)
            // offset in memory to beginning of logicsAndSelectorsOffset bytes
            let logicsAndSelectorsOffset := add(logicsAndSelectors, 32)

            for { } lt(i, selectorsLength) {
                // post actions
                i := add(i, 1)
                selectorsOffset := add(selectorsOffset, 32)
                logicsAddressesOffset := add(logicsAddressesOffset, 32)
                logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 24)
            } {
                // value creation:
                // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff0000000000000000
                logicAndSelectorValue := or(mload(selectorsOffset), shl(64, mload(logicsAddressesOffset)))
                // store the value in the logicsAndSelectors byte array
                mstore(logicsAndSelectorsOffset, logicAndSelectorValue)
            }
        }
    }

    function quickSort(bytes4[] memory selectors, address[] memory facetAddresses) internal pure {
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

            int256 pivotIndex = _partition(selectors, facetAddresses, low, high);

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
        address[] memory facetAddresses,
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

                if (facetAddresses.length == selectors.length) {
                    (facetAddresses[uint256(i)], facetAddresses[uint256(j)]) =
                        (facetAddresses[uint256(j)], facetAddresses[uint256(i)]);
                }
            }
        }

        (selectors[uint256(i + 1)], selectors[uint256(high)]) = (selectors[uint256(high)], selectors[uint256(i + 1)]);

        if (facetAddresses.length == selectors.length) {
            (facetAddresses[uint256(i + 1)], facetAddresses[uint256(high)]) =
                (facetAddresses[uint256(high)], facetAddresses[uint256(i + 1)]);
        }

        return i + 1;
    }
}
