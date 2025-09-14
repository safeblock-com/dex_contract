// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/transferFacet/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/multiswapRouterFacet/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/stargateFacet/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/stargateFacet/LayerZeroFacet.sol";
import { SymbiosisFacet } from "../src/facets/symbiosisFacet/SymbiosisFacet.sol";
import { AcrossFacet } from "../src/facets/acrossFacet/AcrossFacet.sol";
import { CrossCurveFacet } from "../src/facets/crossCurveFacet/CrossCurveFacet.sol";
import { CelerCCTPFacet } from "../src/facets/CCTPFacet/CelerCCTPFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address multiswapRouterFacet;
    address transferFacet;
    address stargateFacet;
    address layerZeroFacet;
    address symbiosisFacet;
    address acrossFacet;
    address crossCurveFacet;
    address celerCCTPFacet;
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
    address prodProxyV3;
    //
    address wrappedNative;
    address layerZeroEndpointV2;
    address symbiosisPortal;
    address permit2;
    address acrossSpokePool;
    address crossCurveUnifiedRouter;
    address celerCCTPProxy;
    address usdc;
    //
    address multisig;
    //
    address authorizedSender;
}

address constant multisig = address(0);

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            multiswapRouterFacet: 0xbF9e94b89D6f4f8DA8e56Bc2F92C058d5e12e1Ae,
            transferFacet: 0x22c9F7E674d52C71b9f00F6e637bd66A6c83D41A,
            stargateFacet: address(0),
            layerZeroFacet: address(0),
            symbiosisFacet: address(1),
            acrossFacet: 0x17bC5E1A8DC29C702F4af5DC939a06c339ccc23e,
            crossCurveFacet: address(1),
            celerCCTPFacet: address(0),
            //
            quoter: 0x7F17EA00590d1A1b6384717058f3C29a06391967,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x453B60E247108B92C3B413bF944853A43da9b850,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x8e9b5E48fc46CDDE5CB41C586C5c21209A053f01,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5,
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: 0x6065A982F04F759b7d2D042D2864e569fad84214,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            multiswapRouterFacet: 0xe514120888329e44414E40f0b1F5Ae4eB3C89F96,
            transferFacet: 0xC69A50AEd37f7c08fe6C602f92922Cffd7E7045A,
            stargateFacet: 0xea2f8aC5e74B9a12A21333e03Ca4b0b51e4CfB2D,
            layerZeroFacet: 0x63b9F6b24Cd07793795D3f0488e34039E9519210,
            symbiosisFacet: address(1),
            acrossFacet: 0x066a0640E451f8FA727DD219b5a93Cb01F3ECF6e,
            crossCurveFacet: address(1),
            celerCCTPFacet: address(1),
            //
            quoter: 0xD27CDB55E82b1FbF69E64C57e1D1D43FdA3854d9,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xD084263a34781e17cB6cd8d39CB1c5F392CCE442,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x4e8E101924eDE233C13e2D8622DC8aED2872d505,
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: address(0),
            usdc: address(0),
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            multiswapRouterFacet: 0x4E8B3593b50942133d0484F90FD38a655e5fFA7D,
            transferFacet: 0x5bd810757d09FD3CD139379c7A8d4321F50C4505,
            stargateFacet: 0x56109b40E7BB0f4C987f9dddA5C5cfCf142Cad2E,
            layerZeroFacet: 0x33E01c15D792c4Aa0927845778863b9617Ed4698,
            symbiosisFacet: address(1),
            acrossFacet: 0x87d84EC6026757593428C5cB73290aFBc6B4472D,
            crossCurveFacet: address(1),
            celerCCTPFacet: 0x0E77029aB1522F38A284A9d3EA59980211822D35,
            //
            quoter: 0x311621eAAea04955ab96F6F2F17DB705c108e8b0,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xCcAfc69a7F75C672501B0f0B819bA03Dab127B46,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x9295ee1d8C5b022Be115A2AD3c30C72E34e7F096,
            crossCurveUnifiedRouter: address(0),
            celerCCTPProxy: 0xB876cc05c3C3C8ECBA65dAc4CF69CaF871F2e0DD,
            usdc: 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Contracts({
            multiswapRouterFacet: 0x5c12c5160697a129AF51fBc94C2BE50eBFD2bF53,
            transferFacet: 0x4bEdfe5B9f35C258376fDDb46D1b2Db2b85ebC00,
            stargateFacet: 0x517c6413bEe56bcCEb62CFA7f411Ef25f80a6195,
            layerZeroFacet: 0xFd58921ec28d7c407ba684DD8dED4F5B22bd4a44,
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            celerCCTPFacet: address(0),
            //
            quoter: 0xcEECc58e3d1A2dBc39ad3EDa5F62775966971952,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x595EeaA4E8A8643bE5E2462f109C94012A472774,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x102c3817Eea7B968bb637590eEEBBb369262f7a5,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xE75C7E85FE6ADd07077467064aD15847E6ba9877,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: 0x9744ae566c64B6B6f7F9A4dD50f7496Df6Fef990,
            usdc: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // optimism
    if (chainId == 10) {
        return Contracts({
            multiswapRouterFacet: 0x3bC7a01b433F232de34132179DdAEE12F7FEE0c2,
            transferFacet: 0x50E4D4a7385992a415A6F27294658B1017cF8701,
            stargateFacet: 0x311621eAAea04955ab96F6F2F17DB705c108e8b0,
            layerZeroFacet: 0x8eb46949e8D707FF8Fd4eB6ad7Bda011B62f8196,
            symbiosisFacet: address(1),
            acrossFacet: address(0),
            crossCurveFacet: address(1),
            celerCCTPFacet: address(0),
            //
            quoter: 0x5c12c5160697a129AF51fBc94C2BE50eBFD2bF53,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x565358F34ecaE13b8E9D97C12b0baE84b87bE476,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x6f26Bf09B1C792e3228e5467807a900A503c0281,
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: 0x697aC93c9263346c5Ad0412F9356D5789a3AA687,
            usdc: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Contracts({
            multiswapRouterFacet: 0x30A46f018C7D7d8eb42098Ec658B123B34E93F68,
            transferFacet: 0x633AbbcE954Fc3fcB3D2e2D27E86B75dE6650d66,
            stargateFacet: 0x6829a3c7bAeCB3eEE4072C9BB6f5d4ccac9dbf03,
            layerZeroFacet: 0x81CD5B260462a06b705Da1C35d16ACF7f37798F5,
            symbiosisFacet: address(1),
            acrossFacet: 0xDF34E00fE0EB9f8a5255E843a83fBa8f43eD62d6,
            crossCurveFacet: address(1),
            celerCCTPFacet: 0xEd14a2D721c1987Ae96842b1bc0E4852a73307c0,
            //
            quoter: 0x4bEdfe5B9f35C258376fDDb46D1b2Db2b85ebC00,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x046684C98C88E940B7321F175972C37A5E1862f5,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x01A3c8E513B758EBB011F7AFaf6C37616c9C24d9,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A,
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: 0x054B95b60BFFACe948Fa4548DA8eE2e212fb7C0a,
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // base
    if (chainId == 8453) {
        return Contracts({
            multiswapRouterFacet: 0x443e430a87d68e285E56FBD76cB4ef60DA0bCe9f,
            transferFacet: 0x0000600c2cAE34743ffA4605fce80bcda2fC1b33,
            stargateFacet: 0x633AbbcE954Fc3fcB3D2e2D27E86B75dE6650d66,
            layerZeroFacet: 0xa1cF9Aa16071F97BcF9AAB75A5A6D79CB53DFb9C,
            symbiosisFacet: address(1),
            acrossFacet: address(0),
            crossCurveFacet: address(1),
            celerCCTPFacet: address(0),
            //
            quoter: 0x90DF6f51165AFEccb379c047d1bc34f70225Fc71,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xfdF5F450CF0dE94F6C0Bf0B2355de1EEb753B39D,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x64D225f5a87E01CF015770815de34f03fe59fE13,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xEE981B2459331AD268cc63CE6167b446AF4161f8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64,
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: 0x243b40e96c6bF21511E53d85c86F6Ec982f9a879,
            usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // scroll
    if (chainId == 534_352) {
        return Contracts({
            multiswapRouterFacet: 0xfDf7b550BD971dF0846872080cE93c67dE00853f,
            transferFacet: 0xACCa97a6F48342d069f19fb4502AC5C5c37541d4,
            stargateFacet: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            layerZeroFacet: 0x595EeaA4E8A8643bE5E2462f109C94012A472774,
            symbiosisFacet: address(1),
            acrossFacet: address(0),
            crossCurveFacet: address(1),
            celerCCTPFacet: address(1),
            //
            quoter: 0x71e1e613f57102A7c921a829848C3823030ed500,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xD7D812de23Dfd953F1431322cE62A0Ca818C9570,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x5300000000000000000000000000000000000004,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x3baD7AD0728f9917d1Bf08af5782dCbD516cDd96,
            crossCurveUnifiedRouter: address(0),
            celerCCTPProxy: address(0),
            usdc: address(0),
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
        });
    }

    // gnosis
    if (chainId == 100) {
        return Contracts({
            multiswapRouterFacet: 0xfdF5F450CF0dE94F6C0Bf0B2355de1EEb753B39D,
            transferFacet: 0xDa7fbeb9D9Ee83194f10E9D84Ad6DCb47A7311Dc,
            stargateFacet: 0x71e1e613f57102A7c921a829848C3823030ed500,
            layerZeroFacet: 0xDE9C11Fc5688f768c92734282d884aC5fB79d4a6,
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            celerCCTPFacet: address(1),
            //
            quoter: 0xF9B37dFa8479C657FddD9fB50dDb75404622EBCe,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xF307b0a60330512D51e4C8e4ddAA3E26D8f08569,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x490555CBa64d606FFf6f82a3A373cEA5d59B3973,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            celerCCTPProxy: address(0),
            usdc: address(0),
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
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
            acrossFacet: address(0),
            crossCurveFacet: address(0),
            celerCCTPFacet: address(0),
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
            prodProxyV3: address(0),
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xd83B5752b42856a08087748dE6095af0bE52d299,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5,
            crossCurveUnifiedRouter: address(0),
            celerCCTPProxy: address(0),
            usdc: address(0),
            //
            multisig: multisig,
            //
            authorizedSender: 0xF4831F2D2E5407471a9a964C791362567cA9Ca78
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
            selectors[i++] = TransferFacet.getNonceForPermit2.selector;
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
            selectors[i++] = MultiswapRouterFacet.multiswap.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap2.selector;
            selectors[i++] = MultiswapRouterFacet.multiswapReverse.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.multiswapRouterFacet;
            ++addressIndex;
        }

        if (contracts.stargateFacet > address(1)) {
            selectors[i++] = StargateFacet.lzEndpoint.selector;
            selectors[i++] = StargateFacet.quoteV2.selector;
            selectors[i++] = StargateFacet.sendStargateV2.selector;
            selectors[i++] = StargateFacet.sendStargate.selector;
            selectors[i++] = StargateFacet.lzCompose.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.stargateFacet;
            ++addressIndex;
        }

        if (contracts.layerZeroFacet > address(1)) {
            selectors[i++] = LayerZeroFacet.eid.selector;
            selectors[i++] = LayerZeroFacet.defaultGasLimit.selector;
            selectors[i++] = LayerZeroFacet.getPeer.selector;
            selectors[i++] = LayerZeroFacet.getGasLimit.selector;
            selectors[i++] = LayerZeroFacet.getDelegate.selector;
            selectors[i++] = LayerZeroFacet.getUlnConfig.selector;
            selectors[i++] = LayerZeroFacet.getNativeSendCap.selector;
            selectors[i++] = LayerZeroFacet.isSupportedEid.selector;
            selectors[i++] = LayerZeroFacet.estimateFee.selector;
            selectors[i++] = LayerZeroFacet.quoteMessage.selector;
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

        if (contracts.acrossFacet > address(1)) {
            selectors[i++] = AcrossFacet.spokePool.selector;
            selectors[i++] = AcrossFacet.sendAcrossDepositV3.selector;
            selectors[i++] = AcrossFacet.sendAcrossDeposit.selector;
            selectors[i++] = AcrossFacet.handleV3AcrossMessage.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.acrossFacet;
            ++addressIndex;
        }

        if (contracts.crossCurveFacet > address(1)) {
            selectors[i++] = CrossCurveFacet.startCrossCurve.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.crossCurveFacet;
            ++addressIndex;
        }

        if (contracts.celerCCTPFacet > address(1)) {
            selectors[i++] = CelerCCTPFacet.quoteTransfer.selector;
            selectors[i++] = CelerCCTPFacet.sendCircleBridge.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.celerCCTPFacet;
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
                }),
                permit2Address: contracts.permit2,
                wrappedNativeAddress: contracts.wrappedNative,
                authorizedSender: contracts.authorizedSender
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

            contracts.multiswapRouterFacet = address(new MultiswapRouterFacet());
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

        if (contracts.acrossFacet == address(0) || isTest) {
            upgrade = true;

            contracts.acrossFacet = address(
                new AcrossFacet({
                    spokePool_: contracts.acrossSpokePool,
                    wrappedNative_: contracts.wrappedNative,
                    endpointV2: contracts.layerZeroEndpointV2
                })
            );
        }

        if (contracts.crossCurveFacet == address(0) || isTest) {
            upgrade = true;

            contracts.crossCurveFacet =
                address(new CrossCurveFacet({ crossCurveRouter: contracts.crossCurveUnifiedRouter }));
        }

        if (contracts.celerCCTPFacet == address(0) || isTest) {
            upgrade = true;

            contracts.celerCCTPFacet = address(
                new CelerCCTPFacet({
                    circleBridge: contracts.celerCCTPProxy,
                    endpointV2: contracts.layerZeroEndpointV2,
                    USDC_: contracts.usdc
                })
            );
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
