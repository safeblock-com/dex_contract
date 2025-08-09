// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/transferFacet/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/multiswapRouterFacet/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/stargateFacet/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/stargateFacet/LayerZeroFacet.sol";
import { SymbiosisFacet } from "../src/facets/symbiosisFacet/SymbiosisFacet.sol";
import { AcrossFacet } from "../src/facets/acrossFacet/AcrossFacet.sol";
import { CrossCurveFacet } from "../src/facets/crossCurveFacet/CrossCurveFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address multiswapRouterFacet;
    address transferFacet;
    address stargateFacet;
    address layerZeroFacet;
    address symbiosisFacet;
    address acrossFacet;
    address crossCurveFacet;
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
    //
    address multisig;
}

address constant multisig = address(0);

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            multiswapRouterFacet: 0x6B3f7569B9366E64066085818d6E61426a0A5f5F,
            transferFacet: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            stargateFacet: 0xc5a484e1A30032e3af1794c595814680644dffe4,
            layerZeroFacet: 0x5fB4C069790315D5183963A4d82A54C07ed1BcC1,
            symbiosisFacet: address(1),
            acrossFacet: 0x09D517Fb8050283a335628BB6B2806bE29ceA372,
            crossCurveFacet: address(1),
            //
            quoter: address(0),
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x453B60E247108B92C3B413bF944853A43da9b850,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x464A62404E5FC95a2a04217f822ee1BC1b7Eb94a,
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
            //
            multisig: multisig
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            multiswapRouterFacet: 0xf63D279E925EABF0329603D7a702aa8e86D22eea,
            transferFacet: 0xc96aa6EC19aE1f79E57075Dd2Fc28B0e81565CdA,
            stargateFacet: 0x17bD505Fb3aD9cB00c057ddf29E7790Ef9997809,
            layerZeroFacet: 0xf86214eA0bc7ea26a7aEaB0ce0723a580Ed7a5CA,
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            //
            quoter: 0x38Ec59De5a9d2a57135901539A9E11B908B1aB6F,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x1A0AbcE7343170E34600d5701e3DA43eE206a9d8,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodProxyV3: 0xA5487594bD2303AF225f8c15E80CED0Da883A0E8,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
            //
            multisig: multisig
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            multiswapRouterFacet: 0x7D1e68b7A5A68dEE988af82cf11562B040bDF05E,
            transferFacet: 0x6829a3c7bAeCB3eEE4072C9BB6f5d4ccac9dbf03,
            stargateFacet: 0x81CD5B260462a06b705Da1C35d16ACF7f37798F5,
            layerZeroFacet: 0x046684C98C88E940B7321F175972C37A5E1862f5,
            symbiosisFacet: address(1),
            acrossFacet: 0xB98f5d653d22E98999263F63C857cf33a3A7b5f8,
            crossCurveFacet: address(1),
            //
            quoter: 0xDF34E00fE0EB9f8a5255E843a83fBa8f43eD62d6,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xc0C67E98d41E44cE4838cd8F8084246c513Eb12e,
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
            //
            multisig: multisig
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Contracts({
            multiswapRouterFacet: 0x1291EF9Fde55e8783faFfBe117F3D30613F85055,
            transferFacet: 0xb2651fB158c2eFeAE836B5445E7dBDe45d21b72f,
            stargateFacet: 0xF7FE08DF80E53687F998Db8dDCaF7Be3cBf17362,
            layerZeroFacet: 0xfb6b52cEbBe47D81c36caDF4049A42BFb1BBe1c5,
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            //
            quoter: 0x4bBD5280C414db8b439E150Ad8178e500B95413A,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x595EeaA4E8A8643bE5E2462f109C94012A472774,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xeCA1098Cd369E957DA00519a8a790fd6d4c042b6,
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
            //
            multisig: multisig
        });
    }

    // optimism
    if (chainId == 10) {
        return Contracts({
            multiswapRouterFacet: 0x443e430a87d68e285E56FBD76cB4ef60DA0bCe9f,
            transferFacet: 0x29D52Db7bD87F825f22a56533E6A4C4B17220507,
            stargateFacet: 0xD22Ef25cdF638188D2abA4205865E4d65C5f46EB,
            layerZeroFacet: 0x422b28F886AC3D0a4AF792DC75077CE44305ABda,
            symbiosisFacet: address(1),
            acrossFacet: 0x4bBD5280C414db8b439E150Ad8178e500B95413A,
            crossCurveFacet: address(1),
            //
            quoter: 0xa1cF9Aa16071F97BcF9AAB75A5A6D79CB53DFb9C,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x166dac13450D1B5E24676D3E8c204a3D3da98B37,
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
            //
            multisig: multisig
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Contracts({
            multiswapRouterFacet: 0xF7FE08DF80E53687F998Db8dDCaF7Be3cBf17362,
            transferFacet: 0xfb6b52cEbBe47D81c36caDF4049A42BFb1BBe1c5,
            stargateFacet: 0xeCA1098Cd369E957DA00519a8a790fd6d4c042b6,
            layerZeroFacet: 0xe1115E14970f96682AF8eA6FC7fB3e7910EB7a10,
            symbiosisFacet: address(1),
            acrossFacet: 0x3cbF4319cBf6d998c203EE8cFcd3EB6165100d75,
            crossCurveFacet: address(1),
            //
            quoter: 0x5C2c0886625fD61E747C93EdF57F2d3dcb00E399,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x34D597654179d34eDFE865994577FAf387b53487,
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
            //
            multisig: multisig
        });
    }

    // base
    if (chainId == 8453) {
        return Contracts({
            multiswapRouterFacet: 0x0c58f09658d72Ffa455100706CFC8aDACE386A99,
            transferFacet: 0x28713F0f1fC6133ACdfeDA7718710f10ca08a3B3,
            stargateFacet: 0xF26e67225141097D4b01A588A2598f2ec2346e34,
            layerZeroFacet: 0x7F17EA00590d1A1b6384717058f3C29a06391967,
            symbiosisFacet: address(1),
            acrossFacet: 0x77cdee5c19Bf6484a8e8C40BEBe4D688bab6a700,
            crossCurveFacet: address(1),
            //
            quoter: 0x61c99d91dFc8D9819E63677A3BEf1e9dfcBa35c2,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xfdF5F450CF0dE94F6C0Bf0B2355de1EEb753B39D,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x64BF7D769F1f8470FF42734f69e056d2A492397C,
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
            //
            multisig: multisig
        });
    }

    // scroll
    if (chainId == 534_352) {
        return Contracts({
            multiswapRouterFacet: 0xF9B37dFa8479C657FddD9fB50dDb75404622EBCe,
            transferFacet: 0x62Fa7C88078BC1DE3C60A4D825891CB414C288f8,
            stargateFacet: 0x82eefc5d2053CC3C33d76F58979cAcd08944C2CC,
            layerZeroFacet: 0xDa7fbeb9D9Ee83194f10E9D84Ad6DCb47A7311Dc,
            symbiosisFacet: address(1),
            acrossFacet: 0xaA2b8D9B4328076Ff656476111F5c654D1d70Eb0,
            crossCurveFacet: address(1),
            //
            quoter: 0xA7c61a0aae5e3CC3484c13B86dD39ABa80E70940,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xc25bED344C4c3885f16d127F23FaDaa82784c2A6,
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
            //
            multisig: multisig
        });
    }

    // gnosis
    if (chainId == 100) {
        return Contracts({
            multiswapRouterFacet: 0x7877c8087F1E152a51162DAdfAA55dD4700279b6,
            transferFacet: 0x72d012ede34937332Eabc80D1B9D2f995AC434c1,
            stargateFacet: 0x605750a4e1d8971d64a7c4FD5f8DF238e06dFFc6,
            layerZeroFacet: 0xC40D56c2cb35E7d0d4c1a5C313500C144b8f5AAD,
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            //
            quoter: 0xE2D0C301c6293a2cA130AF2ACC47051e349079c5,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xF307b0a60330512D51e4C8e4ddAA3E26D8f08569,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x2322D126382844B64E2FbDB1f69fe91A70Db463c,
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
            //
            multisig: multisig
        });
    }

    // unit zero
    if (chainId == 88_811) {
        return Contracts({
            multiswapRouterFacet: 0xa6a39188097bc275593dDb875705491A70DBEC0B,
            transferFacet: 0x995f1B46F71Bc83a90653286e85185D27956687e,
            stargateFacet: address(1),
            layerZeroFacet: address(1),
            symbiosisFacet: address(1),
            acrossFacet: address(1),
            crossCurveFacet: address(1),
            //
            quoter: 0x15ad2B8844a7f42A94F37AdFc90BeeBd5D1c99AA,
            quoterProxy: 0xdF735aCD459014f793E3E7d27F5C598381E23A21,
            proxy: 0xA26c8aC451d9EBbd4B40e8D2Ed91f5c55b989001,
            feeContract: 0x96Fda36A350e40F89Bcdeb5149eFE4C77316F961,
            feeContractProxy: 0xbe35b0b10037e11a6D0A71c326FcF929935A4230,
            //
            prodEntryPoint: 0x48229df22D71eecFf545A3698ACbacc5CF41D658,
            prodProxy: address(0),
            prodProxyV2: address(0),
            prodProxyV3: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            prodFeeContractProxy: 0x911eEd36e5fB42d0202FAA2b0A848d35777eB05F,
            //
            wrappedNative: 0xCF43F7703d9B4E8835f977eF364B4014fA7e856E,
            layerZeroEndpointV2: address(0),
            symbiosisPortal: address(0),
            permit2: 0xf383062455CeF04f5b54C9a4d5FA177FD4bb06b6,
            acrossSpokePool: address(0),
            crossCurveUnifiedRouter: 0xA2A786ff9148f7C88EE93372Db8CBe9e94585c74,
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
            acrossFacet: address(0),
            crossCurveFacet: address(0),
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
            selectors[i++] = AcrossFacet.handleV3AcrossMessage.selector;
            for (uint256 k; k < i - iCache; ++k) {
                addressIndexes[j++] = addressIndex;
            }
            iCache = i;
            facetAddresses[addressIndex] = contracts.acrossFacet;
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
                wrappedNativeAddress: contracts.wrappedNative
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
                new AcrossFacet({ spokePool_: contracts.acrossSpokePool, wrappedNative_: contracts.wrappedNative })
            );
        }

        if (contracts.crossCurveFacet == address(0) || isTest) {
            upgrade = true;

            contracts.crossCurveFacet =
                address(new CrossCurveFacet({ crossCurveRouter: contracts.crossCurveUnifiedRouter }));
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
