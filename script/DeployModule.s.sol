// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { CoinFlippersModule, ICoinFlippersModule } from "../src/modules/CoinFlippersModule.sol";

import { Contracts, getContracts } from "./DeployEngine.sol";
import { EntryPoint } from "../src/EntryPoint.sol";

struct Modules {
    address coinFlippersModule;
    // helper
    address coinFlippersVault;
}

function getModules(uint256 chainId) pure returns (Modules memory) {
    // ethereum
    if (chainId == 1) {
        return Modules({
            coinFlippersModule: 0x62Fa7C88078BC1DE3C60A4D825891CB414C288f8,
            // helper
            coinFlippersVault: 0xA63cB21C43664B762C8401f7FFBBfc3947fF8D70
        });
    }

    // bnb
    if (chainId == 56) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // polygon
    if (chainId == 137) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // avalanche
    if (chainId == 43_114) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // optimism
    if (chainId == 10) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // arbitrum
    if (chainId == 42_161) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // base
    if (chainId == 8453) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    // tron
    if (chainId /* 728126428 testnet */ == 2_494_104_990) {
        return Modules({
            coinFlippersModule: address(1),
            // helper
            coinFlippersVault: address(0)
        });
    }

    Modules memory m;
    return m;
}

contract DeployModule is Script {
    address deployer;

    Modules modules;
    Contracts contracts;

    function run(uint256 version) external {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        contracts = getContracts({ chainId: block.chainid });
        modules = getModules({ chainId: block.chainid });

        if (modules.coinFlippersModule == address(1)) {
            revert("");
        }

        if (modules.coinFlippersModule == address(0)) {
            modules.coinFlippersModule =
                address(new CoinFlippersModule({ coinFlippersVault_: modules.coinFlippersVault }));
        }

        EntryPoint entryPoint;

        if (version > 0) {
            entryPoint = EntryPoint(payable(contracts.prodProxyV2));
        } else {
            entryPoint = EntryPoint(payable(contracts.proxy));
        }

        if (
            entryPoint.getModuleAddress({ moduleSignature: ICoinFlippersModule.deposit.selector })
                != modules.coinFlippersModule
        ) {
            entryPoint.addModule({
                moduleAddress: modules.coinFlippersModule,
                moduleSignature: ICoinFlippersModule.deposit.selector
            });
        }
    }
}
