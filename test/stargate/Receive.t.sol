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
    TransferHelper,
    IEntryPoint
} from "../BaseTest.t.sol";

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

    function test_stargateFacet_lzCompose_shouldRevertIfSenderIsNotLzEndpoint()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.2e18, 0.3e18, 0.3e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_Bakery),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        bytes memory multicallData = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                    abi.encodeCall(ITransferFacet.transferToken, (user, m2Data.tokensOut))
                )
            )
        );

        bytes memory composeMsg = abi.encode(USDT, user, multicallData);

        _resetPrank(user);

        vm.expectRevert(IStargateFacet.StargateFacet_NotLZEndpoint.selector);
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

    function test_stargateFacet_lzCompose_shouldLzCompose()
        external
        checkTokenStorage(Solarray.addresses(USDT, CAKE, USDC))
    {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 0;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.3e18, 0.5e18);
        m2Data.tokenIn = USDC;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDC_CAKE_Cake), Solarray.bytes32s(USDT_USDC_UniV3_100), new bytes32[](0)
        );
        m2Data.tokensOut = Solarray.addresses(USDT, CAKE, USDC);
        m2Data.minAmountsOut = Solarray.uint256s(0, 0, 0);

        deal(USDC, address(entryPoint), 995.1e18);

        address[] memory tokensOut = Solarray.addresses(USDT, CAKE, USDC);

        bytes memory multicallData = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                    abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                )
            )
        );

        bytes memory composeMsg = abi.encode(USDC, user, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        _expectERC20TransferCall(USDC, address(uint160(uint256(USDC_CAKE_Cake))), 995.1e18 * 0.2e18 / 1e18);
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

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailed()
        external
        checkTokenStorage(Solarray.addresses(USDT))
    {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 995.1e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data })[0];

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut + 1);

        bytes memory multicallData = abi.encodeCall(
            IEntryPoint.multicall,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(ITransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        );

        bytes memory composeMsg = abi.encode(USDT, user, multicallData);

        _resetPrank(contracts.layerZeroEndpointV2);

        _expectERC20TransferCall(USDT, user, 995.1e18);
        vm.expectEmit();
        emit CallFailed({
            errorMessage: abi.encodeWithSelector(
                IMultiswapRouterFacet.MultiswapRouterFacet_ValueLowerThanExpected.selector,
                quoterAmountOut,
                m2Data.minAmountsOut[0]
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

    function test_stargateFacet_lzCompose_shouldSendTokensToReceiverIfCallFailedWithNative()
        external
        checkTokenStorage(Solarray.addresses(USDT))
    {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        deal({ to: address(entryPoint), give: 0.001e18 });

        bytes memory multicallData = abi.encodeCall(
            IEntryPoint.multicall, Solarray.bytess(abi.encodeCall(ITransferFacet.unwrapNativeAndTransferTo, (user)))
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
