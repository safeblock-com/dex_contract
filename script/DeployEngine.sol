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
    //
    address wrappedNative;
    address endpointV2;
    address stargateComposerV1;
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
            //
            wrappedNative: address(0),
            endpointV2: address(0),
            stargateComposerV1: address(0)
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            transferFacet: 0x63C870276Ba8f7dC248B89320a7d24f938B5F14C,
            multiswapRouterFacet: 0xaA0e646040eC978059E835764E594af3A130f5Ac,
            stargateFacet: 0xB1368ce5FF0b927F62C41226c630083a8Ea259EF,
            layerZeroFacet: 0x55a8745B020817B4822077F6Ca3113B0E5510cC0,
            //
            quoter: 0x46f4ce97aFd70cd668984C874795941E7Fc591CA,
            quoterProxy: 0x51a85c557cD6Aa35880D55799849dDCD6c20B5Cd,
            proxy: 0x2Ea84370660448fd9017715f2F36727AE64f5Fe3,
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            stargateComposerV1: 0xeCc19E177d24551aA7ed6Bc6FE566eCa726CC8a9
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            transferFacet: 0x29F4Bf32E90cAcb299fC82569670f670d334630a,
            multiswapRouterFacet: 0xD4366D4b3af01111a9a3c97c0dfEdc44A3e8C2cF,
            stargateFacet: 0x29588c2cd38631d3892b3d6B7D0CB0Ad342067F0,
            layerZeroFacet: 0xFB7BeD3D0012C988A107fd3F7A1959e3D9dd30eC,
            //
            quoter: 0xFC08aCb8ab29159Cc864D7c7EC8AF2b611DE0820,
            quoterProxy: 0x51a85c557cD6Aa35880D55799849dDCD6c20B5Cd,
            proxy: 0x2Ea84370660448fd9017715f2F36727AE64f5Fe3,
            //
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            endpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            stargateComposerV1: 0xeCc19E177d24551aA7ed6Bc6FE566eCa726CC8a9
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
            selectors[i++] = StargateFacet.stargateV1Composer.selector;
            selectors[i++] = StargateFacet.quoteV1.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV1.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.sgReceive.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < 8; ++k) {
                facetAddresses[j++] = contracts.stargateFacet;
            }
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
                facetAddresses[j++] = contracts.layerZeroFacet;
            }
        }

        assembly {
            mstore(selectors, i)
            mstore(facetAddresses, j)
        }

        return address(new EntryPoint(getBytesArray(selectors, facetAddresses)));
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

            contracts.multiswapRouterFacet = address(new MultiswapRouterFacet(contracts.wrappedNative));
        }

        if (contracts.transferFacet == address(0) || isTest) {
            upgrade = true;

            contracts.transferFacet = address(new TransferFacet(contracts.wrappedNative));
        }

        if (contracts.stargateFacet == address(0) || isTest) {
            upgrade = true;

            contracts.stargateFacet = address(new StargateFacet(contracts.endpointV2, contracts.stargateComposerV1));
        }

        if (contracts.layerZeroFacet == address(0) || isTest) {
            upgrade = true;

            contracts.layerZeroFacet = address(new LayerZeroFacet(contracts.endpointV2));
        }

        return (contracts, upgrade);
    }

    function getBytesArray(
        bytes4[] memory selectors,
        address[] memory logicAddresses
    )
        internal
        pure
        returns (bytes memory logicsAndSelectors)
    {
        quickSort(selectors, logicAddresses);

        uint256 selectorsLength = selectors.length;
        if (selectorsLength != logicAddresses.length) {
            revert("length of selectors and logicAddresses must be equal");
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
            let logicsAddressesOffset := add(logicAddresses, 32)
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

    function quickSort(bytes4[] memory selectors, address[] memory logicAddresses) internal pure {
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

            int256 pivotIndex = _partition(selectors, logicAddresses, low, high);

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
        address[] memory logicAddresses,
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

                if (logicAddresses.length == selectors.length) {
                    (logicAddresses[uint256(i)], logicAddresses[uint256(j)]) =
                        (logicAddresses[uint256(j)], logicAddresses[uint256(i)]);
                }
            }
        }

        (selectors[uint256(i + 1)], selectors[uint256(high)]) = (selectors[uint256(high)], selectors[uint256(i + 1)]);

        if (logicAddresses.length == selectors.length) {
            (logicAddresses[uint256(i + 1)], logicAddresses[uint256(high)]) =
                (logicAddresses[uint256(high)], logicAddresses[uint256(i + 1)]);
        }

        return i + 1;
    }
}
