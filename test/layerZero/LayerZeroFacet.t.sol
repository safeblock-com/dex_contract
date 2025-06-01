// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BaseTest, IERC20, Solarray, IStargateFacet, LayerZeroFacet, ILayerZeroFacet } from "../BaseTest.t.sol";
import { Origin } from "../../src/facets/bridges/stargate/ILayerZeroEndpointV2.sol";

import "../Helpers.t.sol";

contract LayerZeroFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        ILayerZeroFacet(address(entryPoint)).setDefaultGasLimit({ newDefaultGasLimit: 50_000 });
        ILayerZeroFacet(address(entryPoint)).setDelegate({ delegate: owner });
    }

    // =========================
    // getters and setters
    // =========================

    function test_layerZeroFacet_gettersAndSetters() external {
        _resetPrank(owner);

        new LayerZeroFacet({ endpointV2: contracts.layerZeroEndpointV2 });

        assertEq(ILayerZeroFacet(address(entryPoint)).eid(), 30_102);

        assertEq(ILayerZeroFacet(address(entryPoint)).defaultGasLimit(), 50_000);

        ILayerZeroFacet(address(entryPoint)).setDefaultGasLimit({ newDefaultGasLimit: 100_000 });
        assertEq(ILayerZeroFacet(address(entryPoint)).defaultGasLimit(), 100_000);

        assertTrue(ILayerZeroFacet(address(entryPoint)).isSupportedEid({ remoteEid: 30_101 }));
        assertEq(
            ILayerZeroFacet(address(entryPoint)).getPeer({ remoteEid: 30_101 }),
            bytes32(uint256(uint160(address(entryPoint))))
        );

        vm.expectRevert(ILayerZeroFacet.LayerZeroFacet_LengthMismatch.selector);
        ILayerZeroFacet(address(entryPoint)).setPeers({
            remoteEids: Solarray.uint32s(30_101, 1),
            remoteAddresses: Solarray.bytes32s(bytes32(uint256(uint160(owner))))
        });

        ILayerZeroFacet(address(entryPoint)).setPeers({
            remoteEids: Solarray.uint32s(30_101),
            remoteAddresses: Solarray.bytes32s(bytes32(uint256(uint160(owner))))
        });
        assertEq(ILayerZeroFacet(address(entryPoint)).getPeer({ remoteEid: 30_101 }), bytes32(uint256(uint160(owner))));

        assertEq(ILayerZeroFacet(address(entryPoint)).getDelegate(), owner);

        ILayerZeroFacet(address(entryPoint)).setDelegate({ delegate: address(this) });
        assertEq(ILayerZeroFacet(address(entryPoint)).getDelegate(), address(this));

        assertEq(ILayerZeroFacet(address(entryPoint)).getGasLimit({ remoteEid: 30_101 }), 100_000);

        vm.expectRevert(ILayerZeroFacet.LayerZeroFacet_LengthMismatch.selector);
        ILayerZeroFacet(address(entryPoint)).setGasLimit({
            remoteEids: Solarray.uint32s(30_101, 1),
            gasLimits: Solarray.uint128s(30_000)
        });

        ILayerZeroFacet(address(entryPoint)).setGasLimit({
            remoteEids: Solarray.uint32s(30_101),
            gasLimits: Solarray.uint128s(30_000)
        });
        assertEq(ILayerZeroFacet(address(entryPoint)).getGasLimit({ remoteEid: 30_101 }), 30_000);

        assertEq(ILayerZeroFacet(address(entryPoint)).getNativeSendCap({ remoteEid: 30_101 }), 0.24e18);

        assertTrue(ILayerZeroFacet(address(entryPoint)).isSupportedEid({ remoteEid: 30_101 }));

        assertFalse(
            ILayerZeroFacet(address(entryPoint)).allowInitializePath({
                origin: Origin({ srcEid: 0, sender: bytes32(0), nonce: 1 })
            })
        );

        assertEq(ILayerZeroFacet(address(entryPoint)).nextNonce(0, bytes32(0)), 0);
    }

    // =========================
    // sendDeposit
    // =========================

    uint32 remoteEidV2 = 30_101;
    address stargatePool = 0x138EB30f73BC423c6455C53df6D89CB01d9eBc63;

    function test_layerZeroFacet_sendDeposit_shoudRevertIfFeeNotMet() external {
        uint128 nativeTransferCap = ILayerZeroFacet(address(entryPoint)).getNativeSendCap({ remoteEid: remoteEidV2 });

        uint256 fee = ILayerZeroFacet(address(entryPoint)).estimateFee({
            remoteEid: remoteEidV2,
            nativeAmount: nativeTransferCap,
            to: address(0)
        });

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 _fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: remoteEidV2,
            amountLD: 1000e18,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        vm.expectRevert(ILayerZeroFacet.LayerZeroFacet_FeeNotMet.selector);
        entryPoint.multicall{ value: (fee + _fee) >> 1 }({
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, remoteEidV2, 1000e18, user, 0, bytes(""))),
                abi.encodeCall(ILayerZeroFacet.sendDeposit, (remoteEidV2, nativeTransferCap, user))
            )
        });
    }

    function test_layerZeroFacet_sendDeposit_shoudSendDeposit() external {
        uint128 nativeTransferCap = ILayerZeroFacet(address(entryPoint)).getNativeSendCap({ remoteEid: remoteEidV2 });

        uint256 fee = ILayerZeroFacet(address(entryPoint)).estimateFee({
            remoteEid: remoteEidV2,
            nativeAmount: nativeTransferCap,
            to: address(0)
        });

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 _fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: remoteEidV2,
            amountLD: 1000e18,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        entryPoint.multicall{ value: fee + _fee }({
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, remoteEidV2, 1000e18, user, 0, bytes(""))),
                abi.encodeCall(ILayerZeroFacet.sendDeposit, (remoteEidV2, nativeTransferCap, user))
            )
        });
    }
}
