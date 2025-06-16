// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransferFacet } from "../src/facets/transferFacet/TransferFacet.sol";
import { MultiswapRouterFacet } from "../src/facets/multiswapRouterFacet/MultiswapRouterFacet.sol";
import { StargateFacet } from "../src/facets/stargateFacet/StargateFacet.sol";
import { LayerZeroFacet } from "../src/facets/stargateFacet/LayerZeroFacet.sol";
import { SymbiosisFacet } from "../src/facets/symbiosisFacet/SymbiosisFacet.sol";
import { AcrossFacet } from "../src/facets/acrossFacet/AcrossFacet.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

struct Contracts {
    address multiswapRouterFacet;
    address transferFacet;
    address stargateFacet;
    address layerZeroFacet;
    address symbiosisFacet;
    address acrossFacet;
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
    address acrossSpokePool;
    //
    address multisig;
}

address constant multisig = address(0);

function getContracts(uint256 chainId) pure returns (Contracts memory) {
    // ethereum
    if (chainId == 1) {
        return Contracts({
            multiswapRouterFacet: 0xfDf7b550BD971dF0846872080cE93c67dE00853f,
            transferFacet: 0xa19BFB487265190E387F099D1dA18F57B8986C4E,
            stargateFacet: 0x92493CC018eA0d7c184cd9A0403Fa2d8729c5A02,
            layerZeroFacet: 0xCc5bdcB370BDff54F92bEBF2EF7EE4cD049E45b0,
            symbiosisFacet: 0x96bf81a8Be089CaD3fcB269e24e2a7E599012346,
            acrossFacet: 0xB3b674c653A43895fB5269D665A1De39ae8818d2,
            //
            quoter: 0xD7D812de23Dfd953F1431322cE62A0Ca818C9570,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x453B60E247108B92C3B413bF944853A43da9b850,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5,
            //
            multisig: multisig
        });
    }

    // bnb
    if (chainId == 56) {
        return Contracts({
            multiswapRouterFacet: 0x47A75CD6226570d038443c399181a0E95ADd25B3,
            transferFacet: 0x991AC2Fa8E194118e6FF0681E558564E0446A08C,
            stargateFacet: 0xd4D07c5cd66390833b0bA9E5f6d2c93b83E511c4,
            layerZeroFacet: 0xC962F4A886153E1C01F1a7fD634B9131eF7818ea,
            symbiosisFacet: 0x9EFd12C16476825c2758A999149c2ace5ecD9204,
            acrossFacet: address(1),
            //
            quoter: 0x0E77029aB1522F38A284A9d3EA59980211822D35,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x358EcaB7D54c8C109b9a6915196cCF0f5464d1C1,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
            //
            multisig: multisig
        });
    }

    // polygon
    if (chainId == 137) {
        return Contracts({
            multiswapRouterFacet: 0xfb6b52cEbBe47D81c36caDF4049A42BFb1BBe1c5,
            transferFacet: 0xeCA1098Cd369E957DA00519a8a790fd6d4c042b6,
            stargateFacet: 0xe1115E14970f96682AF8eA6FC7fB3e7910EB7a10,
            layerZeroFacet: 0x3cbF4319cBf6d998c203EE8cFcd3EB6165100d75,
            symbiosisFacet: 0x34D597654179d34eDFE865994577FAf387b53487,
            acrossFacet: 0x443e430a87d68e285E56FBD76cB4ef60DA0bCe9f,
            //
            quoter: 0x422b28F886AC3D0a4AF792DC75077CE44305ABda,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x29D52Db7bD87F825f22a56533E6A4C4B17220507,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x9295ee1d8C5b022Be115A2AD3c30C72E34e7F096,
            //
            multisig: multisig
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Contracts({
            multiswapRouterFacet: 0x17bC5E1A8DC29C702F4af5DC939a06c339ccc23e,
            transferFacet: 0xa51280B52900e808AF87d9BA758066c10a3dFa2a,
            stargateFacet: 0xB13211c7EA9965f5b103d713A6275B6af51FED05,
            layerZeroFacet: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            symbiosisFacet: 0x61c99d91dFc8D9819E63677A3BEf1e9dfcBa35c2,
            acrossFacet: address(1),
            //
            quoter: 0x4FCaEDE7768a2019E6C107CEE935c9E2dd963B68,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x595EeaA4E8A8643bE5E2462f109C94012A472774,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xbF9e94b89D6f4f8DA8e56Bc2F92C058d5e12e1Ae,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xE75C7E85FE6ADd07077467064aD15847E6ba9877,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
            //
            multisig: multisig
        });
    }

    // optimism
    if (chainId == 10) {
        return Contracts({
            multiswapRouterFacet: 0x8e9b5E48fc46CDDE5CB41C586C5c21209A053f01,
            transferFacet: 0x0000600c2cAE34743ffA4605fce80bcda2fC1b33,
            stargateFacet: 0xE06a5011B83c5D2b0e6aCfe54ecf1f46Dc6D7544,
            layerZeroFacet: 0xA1458B50bb651c2B5231186D7CFef8cC469eC51b,
            symbiosisFacet: 0x62B1F797d0b00e79D9bA2a419D20fDC547c0B49F,
            acrossFacet: 0x1291EF9Fde55e8783faFfBe117F3D30613F85055,
            //
            quoter: 0xfb6b52cEbBe47D81c36caDF4049A42BFb1BBe1c5,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xb2651fB158c2eFeAE836B5445E7dBDe45d21b72f,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x6f26Bf09B1C792e3228e5467807a900A503c0281,
            //
            multisig: multisig
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Contracts({
            multiswapRouterFacet: 0xB13211c7EA9965f5b103d713A6275B6af51FED05,
            transferFacet: 0xd36f8CC82EA004B4d0c15BdCf584D19aaD775209,
            stargateFacet: 0x61c99d91dFc8D9819E63677A3BEf1e9dfcBa35c2,
            layerZeroFacet: 0xbF9e94b89D6f4f8DA8e56Bc2F92C058d5e12e1Ae,
            symbiosisFacet: 0x90DF6f51165AFEccb379c047d1bc34f70225Fc71,
            acrossFacet: 0x4FCaEDE7768a2019E6C107CEE935c9E2dd963B68,
            //
            quoter: 0xE06a5011B83c5D2b0e6aCfe54ecf1f46Dc6D7544,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x7E9bF77656C1FB73813e725153c70300C502e56f,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x8e9b5E48fc46CDDE5CB41C586C5c21209A053f01,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x01A3c8E513B758EBB011F7AFaf6C37616c9C24d9,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A,
            //
            multisig: multisig
        });
    }

    // base
    if (chainId == 8453) {
        return Contracts({
            multiswapRouterFacet: 0x6B3f7569B9366E64066085818d6E61426a0A5f5F,
            transferFacet: 0xE846Bc68EC2cE2BC813eBDEB315f24cC46cdf4de,
            stargateFacet: 0xc5a484e1A30032e3af1794c595814680644dffe4,
            layerZeroFacet: 0x5fB4C069790315D5183963A4d82A54C07ed1BcC1,
            symbiosisFacet: 0x09D517Fb8050283a335628BB6B2806bE29ceA372,
            acrossFacet: 0x464A62404E5FC95a2a04217f822ee1BC1b7Eb94a,
            //
            quoter: 0x85Db0f7aBEA9A1232e7617bE69d7988a3221EF15,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xfdF5F450CF0dE94F6C0Bf0B2355de1EEb753B39D,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x35f10C95323C34E5994df76BdeA75aaC8Eb10A6b,
            prodProxy: 0x9AE4De30ad3943e3b65E5DF41e8FB8CC0F0213d7,
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x4200000000000000000000000000000000000006,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0xEE981B2459331AD268cc63CE6167b446AF4161f8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64,
            //
            multisig: multisig
        });
    }

    // scroll
    if (chainId == 534_352) {
        return Contracts({
            multiswapRouterFacet: 0x72d012ede34937332Eabc80D1B9D2f995AC434c1,
            transferFacet: 0x605750a4e1d8971d64a7c4FD5f8DF238e06dFFc6,
            stargateFacet: 0xC40D56c2cb35E7d0d4c1a5C313500C144b8f5AAD,
            layerZeroFacet: 0x2322D126382844B64E2FbDB1f69fe91A70Db463c,
            symbiosisFacet: 0x66207F14770394CAEe61D68cB0BBB7E5b3A78426,
            acrossFacet: 0xf2A3Ca6cBFcF49389973FFB533180Ad82e31A180,
            //
            quoter: 0x995b74546dfa85D5147Fd0B6adCb0c83df11794b,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0x65DfbA5338137e0De3c7e9C11D9BFEd0B02c33b8,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0xADEeA926898688F85fd4c04216FF937b8450Ee1c,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0x5300000000000000000000000000000000000004,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x5Aa5f7f84eD0E5db0a4a85C3947eA16B53352FD4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: 0x3baD7AD0728f9917d1Bf08af5782dCbD516cDd96,
            //
            multisig: multisig
        });
    }

    // gnosis
    if (chainId == 100) {
        return Contracts({
            multiswapRouterFacet: 0x33E3337E3d68aB3b56C86613CCF34CB0d006Ab04,
            transferFacet: 0x7559382f22a50e22d5c6026E04be5cd73Bcfa4c4,
            stargateFacet: 0x2ef78f53965cB6b6BE3DF79e143D07790c3E84b3,
            layerZeroFacet: 0xf145B88a658AAf85A7169caC1769a389675a073A,
            symbiosisFacet: 0x0BF76A83c92AAc1214C7F256A923863a37c40FBe,
            acrossFacet: address(1),
            //
            quoter: 0x4bb53eBbBbAC038248aC3983fF9242Fa76a39C12,
            quoterProxy: 0x13e6aC30fC8E37792F18b1e3D75B8266B0A93734,
            proxy: 0x27d6b06f29802a19c6c1216D540758f32ebD8dE6,
            feeContract: 0xF307b0a60330512D51e4C8e4ddAA3E26D8f08569,
            feeContractProxy: 0x37D8fb3336CB25322741c9A75733CFF3903989e6,
            //
            prodEntryPoint: 0x4b6FeDf62D61A5276e4CAf9853Ea70989cDDc967,
            prodProxy: address(1),
            prodProxyV2: 0x07eA307c40599915177b8d0c2EF0F67871Ba4652,
            prodFeeContractProxy: 0x20F282686b842851C8D7552d6fD095B55dBc775f,
            //
            wrappedNative: 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d,
            layerZeroEndpointV2: 0x1a44076050125825900e736c501f859c50fE728c,
            symbiosisPortal: 0x292fC50e4eB66C3f6514b9E402dBc25961824D62,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            acrossSpokePool: address(0),
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
            acrossSpokePool: 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5,
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
            selectors[i++] = MultiswapRouterFacet.multiswap2.selector;
            selectors[i++] = MultiswapRouterFacet.multiswap2Reverse.selector;
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

        if (contracts.acrossFacet == address(0) || isTest) {
            upgrade = true;

            contracts.acrossFacet = address(
                new AcrossFacet({ spokePool_: contracts.acrossSpokePool, wrappedNative_: contracts.wrappedNative })
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
