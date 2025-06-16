// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Quoter } from "../src/lens/Quoter.sol";
import { EntryPoint } from "../src/EntryPoint.sol";

import { InitialImplementation, Proxy } from "../src/proxy/Proxy.sol";

import { DeployEngine, Contracts, getContracts } from "./DeployEngine.sol";

import { FeeContract } from "../src/FeeContract.sol";

import { LayerZeroFacet } from "../src/facets/stargateFacet/LayerZeroFacet.sol";

import { IOwnable2Step } from "../src/external/IOwnable2Step.sol";

contract Deploy is Script {
    bytes32 constant salt_V1 = keccak256("entry-point-salt-1");
    bytes32 constant quoterSalt = keccak256("quoter-salt-1");
    bytes32 constant feeContractSalt = keccak256("fee-contract-salt-1");

    bytes32 constant salt_V2 = keccak256("entry-point-salt-3");

    bytes32 constant devSalt = keccak256("entry-point-salt-2");
    bytes32 constant devFeeContractSalt = keccak256("fee-contract-salt-2");

    // ===================

    Contracts contracts;
    address deployer;

    function run(uint256 version) external {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        contracts = getContracts({ chainId: block.chainid });

        if (contracts.quoter == address(0)) {
            contracts.quoter = address(new Quoter({ wrappedNative_: contracts.wrappedNative }));

            if (contracts.quoterProxy == address(0)) {
                contracts.quoterProxy = _deployProxy(abi.encode(deployer), quoterSalt);

                InitialImplementation(contracts.quoterProxy).upgradeTo({
                    implementation: contracts.quoter,
                    data: abi.encodeCall(Quoter.initialize, (deployer))
                });
            } else {
                Quoter(contracts.quoterProxy).upgradeTo({ newImplementation: contracts.quoter });
            }
        }

        if (version > 0) {
            bytes32 salt;
            address proxy;
            if (version == 1) {
                proxy = contracts.prodProxy;
                salt = salt_V1;
            } else if (version == 2) {
                proxy = contracts.prodProxyV2;
                salt = salt_V2;
            }

            _setup(_runProd(proxy, salt), contracts.prodFeeContractProxy);
        } else {
            _runDev();
            _setup(contracts.proxy, contracts.feeContractProxy);
        }

        vm.stopBroadcast();
    }

    function _runDev() internal {
        bool upgrade;
        (contracts, upgrade) = DeployEngine.deployImplementations({ contracts: contracts, isTest: false });
        if (upgrade) {
            address entryPoint = DeployEngine.deployEntryPoint({ contracts: contracts });

            if (contracts.proxy == address(0)) {
                contracts.proxy = _deployProxy(abi.encode(deployer), devSalt);

                InitialImplementation(contracts.proxy).upgradeTo({
                    implementation: entryPoint,
                    data: abi.encodeCall(EntryPoint.initialize, (deployer))
                });
            } else {
                EntryPoint(payable(contracts.proxy)).upgradeTo({ newImplementation: entryPoint });
            }
        }

        if (contracts.feeContract == address(0)) {
            contracts.feeContract = address(new FeeContract());

            if (contracts.feeContractProxy == address(0)) {
                contracts.feeContractProxy = _deployProxy(abi.encode(deployer), devFeeContractSalt);

                InitialImplementation(contracts.feeContractProxy).upgradeTo({
                    implementation: contracts.feeContract,
                    data: abi.encodeCall(FeeContract.initialize, (deployer, contracts.proxy))
                });
            } else {
                FeeContract(payable(contracts.feeContractProxy)).upgradeTo({ newImplementation: contracts.feeContract });
            }
        }
    }

    function _runProd(address proxy, bytes32 salt) internal returns (address) {
        if (proxy == address(0)) {
            proxy = _deployProxy(abi.encode(deployer), salt);

            InitialImplementation(proxy).upgradeTo({
                implementation: contracts.prodEntryPoint,
                data: abi.encodeCall(EntryPoint.initialize, (deployer))
            });
        } else if (_getProxyImplementation(proxy) != contracts.prodEntryPoint) {
            EntryPoint(payable(proxy)).upgradeTo({ newImplementation: contracts.prodEntryPoint });
        }

        if (contracts.prodFeeContractProxy == address(0)) {
            contracts.prodFeeContractProxy = _deployProxy(abi.encode(deployer), feeContractSalt);

            InitialImplementation(contracts.prodFeeContractProxy).upgradeTo({
                implementation: contracts.feeContract,
                data: abi.encodeCall(FeeContract.initialize, (deployer, proxy))
            });
        } else if (_getProxyImplementation(contracts.prodFeeContractProxy) != contracts.feeContract) {
            FeeContract(payable(contracts.prodFeeContractProxy)).upgradeTo({ newImplementation: contracts.feeContract });
        }

        return proxy;
    }

    function _setup(address proxy, address feeContractProxy) internal {
        (address feeContract, uint256 fee) = EntryPoint(payable(proxy)).getFeeContractAddressAndFee();
        if (fee != 300 || feeContract == address(0)) {
            // 0.03%
            EntryPoint(payable(proxy)).setFeeContractAddressAndFee({ feeContractAddress: feeContractProxy, fee: 300 });
        }

        LayerZeroFacet _layerZeroFacet = LayerZeroFacet(proxy);

        if (_layerZeroFacet.getDelegate() == address(0)) {
            _layerZeroFacet.setDelegate({ delegate: deployer });
        }
        if (_layerZeroFacet.defaultGasLimit() == 0) {
            _layerZeroFacet.setDefaultGasLimit({ newDefaultGasLimit: 50_000 });
        }

        if (Quoter(contracts.quoterProxy).getRouter() != contracts.proxy) {
            if (contracts.proxy > address(0)) {
                Quoter(contracts.quoterProxy).setRouter({ router: contracts.proxy });
            }
        }
    }

    function _getProxyImplementation(address proxy) internal view returns (address impl) {
        bytes32 _impl = vm.load(address(proxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        assembly ("memory-safe") {
            impl := _impl
        }
    }

    function _deployProxy(bytes memory constructorArgs, bytes32 _salt) internal returns (address addr) {
        bytes memory bytecode = abi.encodePacked(
            hex"608060405234801561001057600080fd5b5060405161064f38038061064f83398101604081905261002f916101c7565b8060001955610074604051610043906101ba565b604051809103906000f08015801561005f573d6000803e3d6000fd5b5060408051602081019091526000815261007a565b50610226565b6100838261015d565b6040516001600160a01b038316907fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b90600090a280511561015157600080836001600160a01b0316836040516100d991906101f7565b600060405180830381855af49150503d8060008114610114576040519150601f19603f3d011682016040523d82523d6000602084013e610119565b606091505b50915091508161014b5780511561013257805181602001fd5b60405163e02784b560e01b815260040160405180910390fd5b50505050565b610159610199565b5050565b803b61017557634a4a0aa2600052806020526024601cfd5b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55565b34156101b85760405163811fbc6360e01b815260040160405180910390fd5b565b61038d806102c283390190565b6000602082840312156101d957600080fd5b81516001600160a01b03811681146101f057600080fd5b9392505050565b6000825160005b8181101561021857602081860181015185830152016101fe565b506000920191825250919050565b608e806102346000396000f3fe608060405236600a57005b600060337f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5490565b90503660008037600080366000845af43d6000803e8080156053573d6000f35b3d6000fdfea2646970667358221220064f3bd5e34592ee91aec04ca124290ae532ff39ff36a49f24abd002edead1fa64736f6c63430008130033608060405234801561001057600080fd5b5061036d806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80636fbc15e914610030575b600080fd5b61004361003e36600461022b565b610045565b005b600019805433146100625763483ffb99600052336020526024601cfd5b600090556100708282610074565b5050565b61007d82610186565b60405173ffffffffffffffffffffffffffffffffffffffff8316907fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b90600090a280511561017e576000808373ffffffffffffffffffffffffffffffffffffffff16836040516100ed9190610308565b600060405180830381855af49150503d8060008114610128576040519150601f19603f3d011682016040523d82523d6000602084013e61012d565b606091505b5091509150816101785780511561014657805181602001fd5b6040517fe02784b500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b50505050565b6100706101c2565b803b61019e57634a4a0aa2600052806020526024601cfd5b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55565b34156101fa576040517f811fbc6300000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6000806040838503121561023e57600080fd5b823573ffffffffffffffffffffffffffffffffffffffff8116811461026257600080fd5b9150602083013567ffffffffffffffff8082111561027f57600080fd5b818501915085601f83011261029357600080fd5b8135818111156102a5576102a56101fc565b604051601f8201601f19908116603f011681019083821181831017156102cd576102cd6101fc565b816040528281528860208487010111156102e657600080fd5b8260208601602083013760006020848301015280955050505050509250929050565b6000825160005b81811015610329576020818601810151858301520161030f565b50600092019182525091905056fea26469706673582212207bb2ef0dbbfd01c62a9ac79533e04113da096669f1ddc680bf4a347f593ca36464736f6c63430008130033",
            constructorArgs
        );

        assembly ("memory-safe") {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)

            if iszero(addr) { revert(0, 0) }
        }
    }
}
