// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    IStargateFacet,
    ILayerZeroComposer,
    OFTComposeMsgCodec,
    TransferHelper
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract ReceiveStargateFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: address(entryPoint), give: 995.1e18 });
    }

    // =========================
    // lzCompose
    // =========================

    function test_stargateFacet_lzCompose_shouldRevertIfSenderIsNotLzEndpoint() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 0;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(USDT_USDC_UniV3_100);

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(ITransferFacet.transferToken, (USDC, 0, user))
            )
        );

        bytes memory composeMsg =
            abi.encode(USDT, user, 0x00000000000000000000000000000000000000000000000000000000000000e8, multicallData);

        _resetPrank(user);

        vm.expectRevert(IStargateFacet.NotLZEndpoint.selector);
        ILayerZeroComposer(address(entryPoint)).lzCompose({
            _from: user,
            _guid: bytes32(uint256(1)),
            _message: OFTComposeMsgCodec.encode({
                _nonce: 1,
                _srcEid: 30_101,
                _amountLD: 995.1e18,
                _composeMsg: abi.encodePacked(hex"000000000000000000000000", entryPoint, composeMsg)
            }),
            _executor: contracts.layerZeroEndpointV2,
            _extraData: bytes("")
        });
    }

    function test_stargateFacet_lzCompose_shouldLzCompose() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 0;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(USDT_USDC_UniV3_100);

        deal(USDT, address(entryPoint), 995.1e18);

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(ITransferFacet.transferToken, (USDC, 0, user))
            )
        );

        bytes memory composeMsg =
            abi.encode(USDT, user, 0x00000000000000000000000000000000000000000000000000000000000000e8, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        ILayerZeroComposer(address(entryPoint)).lzCompose({
            _from: user,
            _guid: bytes32(uint256(1)),
            _message: OFTComposeMsgCodec.encode({
                _nonce: 1,
                _srcEid: 30_101,
                _amountLD: 995.1e18,
                _composeMsg: abi.encodePacked(hex"000000000000000000000000", entryPoint, composeMsg)
            }),
            _executor: contracts.layerZeroEndpointV2,
            _extraData: bytes("")
        });
    }

    event CallFailed(bytes errorMessage);

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailed() external {
        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(ITransferFacet.transferToken, (USDT, 0, user)),
                abi.encodeCall(ITransferFacet.transferToken, (USDT, 0, user))
            )
        );

        bytes memory composeMsg =
            abi.encode(USDT, user, 0x00000000000000000000000000000000000000000000000000000000000000e8, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        _expectERC20TransferCall(USDT, user, 995.1e18);
        vm.expectEmit();
        emit CallFailed({ errorMessage: abi.encodeWithSelector(TransferHelper.TransferHelper_TransferError.selector) });
        ILayerZeroComposer(address(entryPoint)).lzCompose({
            _from: user,
            _guid: bytes32(uint256(1)),
            _message: OFTComposeMsgCodec.encode({
                _nonce: 1,
                _srcEid: 30_101,
                _amountLD: 995.1e18,
                _composeMsg: abi.encodePacked(hex"000000000000000000000000", entryPoint, composeMsg)
            }),
            _executor: contracts.layerZeroEndpointV2,
            _extraData: bytes("")
        });
    }

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailedWithNative() external {
        deal({ to: address(entryPoint), give: 0.001e18 });

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (USDC, 21, user)))
        );

        bytes memory composeMsg = abi.encode(
            address(0), user, 0x00000000000000000000000000000000000000000000000000000000000000e8, multicallData
        );

        _resetPrank(contracts.layerZeroEndpointV2);

        vm.expectEmit();
        emit CallFailed({ errorMessage: abi.encodeWithSelector(TransferHelper.TransferHelper_TransferError.selector) });
        ILayerZeroComposer(address(entryPoint)).lzCompose({
            _from: user,
            _guid: bytes32(uint256(1)),
            _message: OFTComposeMsgCodec.encode({
                _nonce: 1,
                _srcEid: 30_101,
                _amountLD: 0.001e18,
                _composeMsg: abi.encodePacked(hex"000000000000000000000000", entryPoint, composeMsg)
            }),
            _executor: contracts.layerZeroEndpointV2,
            _extraData: bytes("")
        });

        assertEq(address(entryPoint).balance, 0);
    }
}
