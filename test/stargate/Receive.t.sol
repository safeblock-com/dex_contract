// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract ReceiveStargateFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: address(entryPoint), give: 995.1e18 });
    }

    // =========================
    // lzCompose
    // =========================

    function test_stargateFacet_lzCompose_shouldRevertIfSenderIsNotLzEndpoint() external checkStorage {
        _resetPrank(user);

        vm.expectRevert(IErrors.StargateFacet_NotLZEndpoint.selector);
        ILayerZeroComposer(address(entryPoint)).lzCompose({
            _from: user,
            _guid: bytes32(uint256(1)),
            _message: OFTComposeMsgCodec.encode({
                _nonce: 1,
                _srcEid: 30_101,
                _amountLD: 995.1e18,
                _composeMsg: abi.encodePacked(hex"000000000000000000000000", entryPoint, bytes(""))
            }),
            _executor: contracts.layerZeroEndpointV2,
            _extraData: bytes("")
        });
    }

    function test_stargateFacet_lzCompose_shouldLzCompose() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDC_CAKE_Cake, 0.2e18), _encodePercentageInPool(USDT_USDC_UniV3_100, 0.8e18)
            )
        );
        mData.tokensOut = Solarray.addresses(USDT, CAKE);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(995.1e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        deal({ token: USDC, to: address(entryPoint), give: 995.1e18 });

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes[])",
            (
                Solarray.bytess(
                    abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                    abi.encodeCall(ITransferFacet.transferToken, (user, mData.tokensOut))
                )
            )
        );

        bytes memory composeMsg = abi.encode(USDC, user, multicallData);

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

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailed() external checkStorage {
        deal({ token: USDC, to: address(entryPoint), give: 995.1e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDC_CAKE_Cake, 0.2e18), _encodePercentageInPool(USDT_USDC_UniV3_100, 0.8e18)
            )
        );
        mData.tokensOut = Solarray.addresses(USDT, CAKE);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(995.1e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        uint256 quoterAmountOut = mData.minAmountsOut[0];
        mData.minAmountsOut[0] *= 2;

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes[])",
            Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(ITransferFacet.transferToken, (user, mData.tokensOut))
            )
        );

        bytes memory composeMsg = abi.encode(USDC, user, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        _expectERC20TransferCall(USDC, user, 995.1e18);
        vm.expectEmit();
        emit CallFailed({
            errorMessage: abi.encodeWithSelector(
                IErrors.ValueLowerThanExpected.selector, quoterAmountOut, mData.minAmountsOut[0]
            )
        });
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

    event TransferNative(address to) anonymous;

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailedWithNative() external checkStorage {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        deal({ to: address(entryPoint), give: 0.001e18 });

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes[])", Solarray.bytess(abi.encodeCall(ITransferFacet.unwrapNativeAndTransferTo, (user)))
        );

        bytes memory composeMsg = abi.encode(address(0), user, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        vm.expectEmitAnonymous();
        emit TransferNative({ to: user });
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
