// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/bridges/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/bridges/LayerZeroFacet.sol";
import { SymbiosisFacet } from "../src/facets/bridges/SymbiosisFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address multiswapRouterFacet;
    address transferFacet;
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
    address prodProxyV2;
    //
    address wrappedNative;
    address layerZeroEndpointV2;
    address symbiosisPortal;
    address permit2;
    //
    address multisig;
}

address constant multisig = address(0);

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            multiswapRouterFacet: 0x4FF57397049F32FB6A7c8EA65d7C1dA15b4e309B,
            transferFacet: 0x33E3337E3d68aB3b56C86613CCF34CB0d006Ab04,
            stargateFacet: 0x7559382f22a50e22d5c6026E04be5cd73Bcfa4c4,
            layerZeroFacet: 0x2ef78f53965cB6b6BE3DF79e143D07790c3E84b3,
            symbiosisFacet: 0xf145B88a658AAf85A7169caC1769a389675a073A,
            //
            quoter: 0x2322D126382844B64E2FbDB1f69fe91A70Db463c,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x453B60E247108B92C3B413bF944853A43da9b850,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xE2D0C301c6293a2cA130AF2ACC47051e349079c5,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
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
            multiswapRouterFacet: 0x1291EF9Fde55e8783faFfBe117F3D30613F85055,
            transferFacet: 0xaA57cb7c180100Ea5C8ed2868F72037B0e084A15,
            stargateFacet: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            layerZeroFacet: 0xe1F49D9ADa84de24dfb35aa5DFDAeE8edcCFd5ce,
            symbiosisFacet: 0xc81836107746458e2C0C45eB6a2E5cf22052090c,
            //
            quoter: 0xA1458B50bb651c2B5231186D7CFef8cC469eC51b,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xb2651fB158c2eFeAE836B5445E7dBDe45d21b72f,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
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
            multiswapRouterFacet: 0x64BF7D769F1f8470FF42734f69e056d2A492397C,
            transferFacet: 0xD7D812de23Dfd953F1431322cE62A0Ca818C9570,
            stargateFacet: 0x8fa29093a1c62288220fC894077007A4671858EF,
            layerZeroFacet: 0xE485932717068eCB9B391519d7800eaDB6EbD0c9,
            symbiosisFacet: 0x0392238689977c8d34bAc6A53f2D62489d7362DB,
            //
            quoter: 0x7F17EA00590d1A1b6384717058f3C29a06391967,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x22c9F7E674d52C71b9f00F6e637bd66A6c83D41A,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
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
            multiswapRouterFacet: 0x35f10C95323C34E5994df76BdeA75aaC8Eb10A6b,
            transferFacet: 0xa19BFB487265190E387F099D1dA18F57B8986C4E,
            stargateFacet: 0x92493CC018eA0d7c184cd9A0403Fa2d8729c5A02,
            layerZeroFacet: 0xCc5bdcB370BDff54F92bEBF2EF7EE4cD049E45b0,
            symbiosisFacet: 0x96bf81a8Be089CaD3fcB269e24e2a7E599012346,
            //
            quoter: 0x09D517Fb8050283a335628BB6B2806bE29ceA372,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x595EeaA4E8A8643bE5E2462f109C94012A472774,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xaA57cb7c180100Ea5C8ed2868F72037B0e084A15,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
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
            multiswapRouterFacet: 0xF059b231973e638290f3AcAD7dAE73662Bb06D8B,
            transferFacet: 0xf9Fe66d241BF32610a557c204a0A660348965481,
            stargateFacet: 0x18Df5169aB4b6794cB1A61ADaf4511678e3E3e23,
            layerZeroFacet: 0x8df74FE7575b219155f4F890159b3D9663D4c39D,
            symbiosisFacet: 0x2163682DCf72d01679136f3387E794D51cB006c7,
            //
            quoter: 0xe1F49D9ADa84de24dfb35aa5DFDAeE8edcCFd5ce,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x9555c6640E1812560Bb101a377edD3EC416935A3,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
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
            multiswapRouterFacet: 0x464A62404E5FC95a2a04217f822ee1BC1b7Eb94a,
            transferFacet: 0x8df74FE7575b219155f4F890159b3D9663D4c39D,
            stargateFacet: 0x2163682DCf72d01679136f3387E794D51cB006c7,
            layerZeroFacet: 0x92493CC018eA0d7c184cd9A0403Fa2d8729c5A02,
            symbiosisFacet: 0xCc5bdcB370BDff54F92bEBF2EF7EE4cD049E45b0,
            //
            quoter: 0x5fB4C069790315D5183963A4d82A54C07ed1BcC1,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x35f10C95323C34E5994df76BdeA75aaC8Eb10A6b,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x01A3c8E513B758EBB011F7AFaf6C37616c9C24d9,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // base
    if (chainId == 8453) {
        return Contracts({
            multiswapRouterFacet: 0x917213eDBEF61B83bc8c80f23Ba16b60Ebe68204,
            transferFacet: 0x4FF57397049F32FB6A7c8EA65d7C1dA15b4e309B,
            stargateFacet: 0xE2D0C301c6293a2cA130AF2ACC47051e349079c5,
            layerZeroFacet: 0x463Bb4d10B9e9194fD8248DF9cE9c00075f645c2,
            symbiosisFacet: 0xF9B37dFa8479C657FddD9fB50dDb75404622EBCe,
            //
            quoter: 0x490555CBa64d606FFf6f82a3A373cEA5d59B3973,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xfdF5F450CF0dE94F6C0Bf0B2355de1EEb753B39D,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xD2A7A4cF1B25B92f47B4A702276DefbB42F45e77,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xEE981B2459331AD268cc63CE6167b446AF4161f8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // scroll
    if (chainId == 534_352) {
        return Contracts({
            multiswapRouterFacet: 0x16a35020a2D45f80cc156649D57E4Cc9d4fC74D2,
            transferFacet: 0x15ad2B8844a7f42A94F37AdFc90BeeBd5D1c99AA,
            stargateFacet: 0xEd02D5A7822d474c21F6e239b81e2ACf1137Ace8,
            layerZeroFacet: 0xa6a39188097bc275593dDb875705491A70DBEC0B,
            symbiosisFacet: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            //
            quoter: 0xe9BEbFC505a738A58319F509EfB51A8ac6c8008f,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x48229df22D71eecFf545A3698ACbacc5CF41D658,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x5300000000000000000000000000000000000004,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // gnosis
    if (chainId == 100) {
        return Contracts({
            multiswapRouterFacet: 0x3E1D733045E7abdC0bd28A272b45cC8896528bB2,
            transferFacet: 0xA26c8aC451d9EBbd4B40e8D2Ed91f5c55b989001,
            stargateFacet: 0xe197BDD7b8bB8f2Ab15c9822602A35f7645a88aF,
            layerZeroFacet: 0x96Fda36A350e40F89Bcdeb5149eFE4C77316F961,
            symbiosisFacet: 0xbe35b0b10037e11a6D0A71c326FcF929935A4230,
            //
            quoter: 0x1A67084d692Cdb88b0c17Dcb57A636A2b493938B,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xF307b0a60330512D51e4C8e4ddAA3E26D8f08569,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x76126f040aF711bE697675137557524Ed79A280B,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            //
            multisig: multisig
        });
    }

    // tron
    if (chainId /* 728126428 testnet */ == 2_494_104_990) {
        return Contracts({
            multiswapRouterFacet: address(0),
            transferFacet: address(0),
            stargateFacet: address(0),
            layerZeroFacet: address(0),
            symbiosisFacet: address(0),
            //
            quoter: address(0),
            quoterProxy: address(0),
            proxy: address(0),
            feeContract: address(0),
            feeContractProxy: address(0),
            //
            prodEntryPoint: address(0),
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: address(0),
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xd83B5752b42856a08087748dE6095af0bE52d299,
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
        uint256 iCache;

        if (contracts.transferFacet != address(0)) {
            // transfer Facet
            selectors[i++] = TransferFacet.getNonceForPermit2.selector;
            selectors[i++] = TransferFacet.transferFromPermit2.selector;
            selectors[i++] = TransferFacet.transferToken.selector;
            selectors[i++] = TransferFacet.unwrapNativeAndTransferTo.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.transferFacet;
            ++addressIndex;
        }

        if (contracts.multiswapRouterFacet != address(0)) {
            // multiswap Facet
            selectors[i++] = MultiswapRouterFacet.wrappedNative.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap2.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.multiswapRouterFacet;
            ++addressIndex;
        }

        if (contracts.stargateFacet != address(0)) {
            selectors[i++] = StargateFacet.lzEndpoint.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
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
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.layerZeroFacet;
            ++addressIndex;
        }

        if (contracts.symbiosisFacet > address(1)) {
            selectors[i++] = SymbiosisFacet.portal.selector;
            selectors[i++] = SymbiosisFacet.sendSymbiosis.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
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

    function deployImplementations(
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
