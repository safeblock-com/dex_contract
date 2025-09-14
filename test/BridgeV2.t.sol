// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.t.sol";

import "./Helpers.t.sol";

contract BridgeV2Test is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: USDC, to: user, give: 1000e18 });
        deal({ token: WBNB, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // crossChainMulticall
    // =========================

    function test_entryPoint_crossChainMulticall_shouldRevertIfDataSelectorIsNotMultiswap() external {
        _resetPrank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.EntryPoint_SelectorNotAllowed.selector, ITransferFacet.transferToken.selector
            )
        );
        entryPoint.crossChainMulticall({
            depositAddress: address(0),
            feeAmount: 0,
            token: address(0),
            extraData: bytes(""),
            data: abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT)))
        });
    }

    function test_entryPoint_crossChainMulticall_shouldRevertIfTokenNotActualTokenOutFromBridge() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        _resetPrank(contracts.authorizedSender);

        vm.expectRevert(IEntryPoint.EntryPoint_InvalidDepositAddress.selector);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 0,
            token: USDC,
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldRevertIfSenderNotAuthorizedSenderOrDepositOwner() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        _resetPrank(makeAddr("imposter"));

        vm.expectRevert(IEntryPoint.EntryPoint_UnauthorizedSender.selector);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 100e18,
            token: address(0),
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldRevertIfDepositAddressAfterDeploymentNotSame() external {
        (address depositAddress,) = _lzReceive(USDT);

        _resetPrank(contracts.authorizedSender);

        vm.expectRevert(IEntryPoint.EntryPoint_InvalidDepositAddress.selector);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 100e18,
            token: address(0),
            extraData: abi.encode(
                Solarray.bytess(
                    abi.encodeCall(ITransferFacet.transferToken, (contracts.authorizedSender, Solarray.addresses(USDT)))
                )
            ),
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldRevertIfDepositAddressAlreadyDeployed() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        deal({ token: USDT, to: depositAddress, give: 1000e18 });

        _resetPrank(contracts.authorizedSender);

        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 0,
            token: USDT,
            extraData: extraData,
            data: bytes("")
        });

        vm.expectRevert(IEntryPoint.EntryPoint_InvalidDepositAddress.selector);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 0,
            token: USDT,
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldRevertIfDepositAddressBalanceIsZero() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        _resetPrank(contracts.authorizedSender);

        vm.expectRevert(Utils.UnexpectedZeroValue.selector);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 0,
            token: USDT,
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldJustSendTokenToUserIfFeeAmountEqTokenAmount() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        deal({ token: USDT, to: depositAddress, give: 1000e18 });

        _resetPrank(contracts.authorizedSender);

        _expectERC20TransferCall(USDT, user, 1000e18);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 1000e18,
            token: USDT,
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_shouldJustSendTokenToUserIfFeeAmountGtTokenAmount() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        deal({ token: USDT, to: depositAddress, give: 1000e18 });

        _resetPrank(contracts.authorizedSender);

        _expectERC20TransferCall(USDT, user, 1000e18);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 1100e18,
            token: USDT,
            extraData: extraData,
            data: bytes("")
        });
    }

    function test_entryPoint_crossChainMulticall_callFailed_shouldTransferTokenToUser() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(USDT);

        deal({ token: USDT, to: depositAddress, give: 1000e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Bakery, 1e18)));
        mData.tokensOut = Solarray.addresses(USDT);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(1000e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        bytes memory data = abi.encodeCall(MultiswapRouterFacet.multiswap, (mData));

        _resetPrank(contracts.authorizedSender);

        _expectERC20TransferCall(USDT, contracts.authorizedSender, 10e18);
        _expectERC20TransferCall(USDT, user, 990e18);
        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 10e18,
            token: USDT,
            extraData: extraData,
            data: data
        });
    }

    function test_entryPoint_crossChainMulticall_callFailed_shouldTransferNativeToUser() external {
        (address depositAddress, bytes memory extraData) = _lzReceive(address(0));

        deal({ to: depositAddress, give: 1000e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Bakery, 1e18)));
        mData.tokensOut = Solarray.addresses(USDT);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(1000e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        bytes memory data = abi.encodeCall(MultiswapRouterFacet.multiswap, (mData));

        _resetPrank(contracts.authorizedSender);

        uint256 senderBalanceBefore = contracts.authorizedSender.balance;
        uint256 userBalanceBefore = user.balance;

        entryPoint.crossChainMulticall({
            depositAddress: depositAddress,
            feeAmount: 10e18,
            token: address(0),
            extraData: extraData,
            data: data
        });

        assertEq(contracts.authorizedSender.balance, senderBalanceBefore + 10e18);
        assertEq(user.balance, userBalanceBefore + 990e18);
    }

    uint32 dstEidV2 = 30_101;
    address stargatePool = 0x138EB30f73BC423c6455C53df6D89CB01d9eBc63;

    function test_stargateFacet_sendStargate_shouldSendStargate() external checkStorage {
        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 fee, uint256 amountOut) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 1000e18,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        address[] memory tokensOut = Solarray.addresses(USDT);

        uint256 messageFee = LayerZeroFacet(address(entryPoint)).quoteMessage({
            remoteEid: dstEidV2,
            extraData: abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
        });

        assertApproxEqAbs(amountOut, 1000e18, 1000e18 * 0.997e18 / 1e18);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDT, stargatePool, 1000e18);
        entryPoint.multicall{ value: fee + messageFee }({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDT),
                amounts: Solarray.uint256s(1000e18)
            }),
            data: Solarray.bytess(
                abi.encodeCall(
                    StargateFacet.sendStargate,
                    (
                        stargatePool,
                        dstEidV2,
                        address(0),
                        address(0),
                        abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_stargateFacet_quoteV2_shouldUseAllPathIfAmountLDIsGreaterThan() external checkStorage {
        _resetPrank(user);

        IStargate pool = IStargate(stargatePool);

        address token = pool.token();

        uint256 paths = pool.paths({ dstEid: dstEidV2 });

        uint256 tokenRate = 10 ** (IERC20(token).decimals() - pool.sharedDecimals());

        uint256 amountPath = paths * tokenRate;
        uint256 amountToSend = amountPath * 1.1e18 / 1e18;

        deal({ token: token, to: user, give: amountToSend });

        (uint256 fee, uint256 amountOut) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: amountToSend,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        assertLt(amountOut, amountPath);

        IERC20(token).approve({ spender: address(entryPoint), amount: amountToSend });

        address[] memory tokensOut = Solarray.addresses(USDT);

        uint256 messageFee = LayerZeroFacet(address(entryPoint)).quoteMessage({
            remoteEid: dstEidV2,
            extraData: abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
        });

        vm.expectRevert();
        entryPoint.multicall{ value: fee + messageFee }({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDT),
                amounts: Solarray.uint256s(amountToSend)
            }),
            data: Solarray.bytess(
                abi.encodeCall(
                    StargateFacet.sendStargate,
                    (
                        stargatePool,
                        dstEidV2,
                        address(0),
                        address(0),
                        abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_layerZeroFacet_lzReceive_shouldRevertIfNotLZEndpoint() external checkStorage {
        _resetPrank(owner);

        uint256 nonce = 0;
        uint256 srcChainId = 1;
        bytes memory extraData =
            abi.encode(Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT)))));

        bytes memory bytecode = abi.encodePacked(
            hex"608160113439333d60010152608134f3fe7f00000000000000000000000000000000000000000000000000000000000000003381146029575b005b3680600014607057602014603c575b6027565b60006044601c8280948135906370a0823183523060205260206040602486855afa5063a9059cbb83526020525af150386038565b5060008080809347905af15038603856",
            extraData
        );

        address depositAddress;
        address _entryPoint = address(entryPoint);
        address _user = user;
        assembly ("memory-safe") {
            let ptr := mload(64)
            mstore(0, _user)
            mstore(32, add(shl(32, 0), 1))

            let salt := keccak256(0, 64)

            mstore(0, add(shl(248, 0xff), shl(88, _entryPoint)))
            mstore(21, salt)
            mstore(53, keccak256(add(bytecode, 32), mload(bytecode))) // bytecode hash

            depositAddress := and(keccak256(0, 85), ADDRESS_MASK)

            mstore(64, ptr)
        }

        bytes memory message = abi.encode(depositAddress, user, nonce, srcChainId, USDC, 1000e18, extraData);

        Origin memory origin;

        vm.expectRevert(ILayerZeroFacet.LayerZeroFacet_NotLZEndpoint.selector);
        LayerZeroFacet(address(entryPoint)).lzReceive({
            origin: origin,
            guid: bytes32(0),
            message: message,
            executor: address(0),
            extraData: extraData
        });
    }

    function _lzReceive(address token) internal returns (address depositAddress, bytes memory extraData) {
        _resetPrank(contracts.layerZeroEndpointV2);

        uint256 nonce = 0;
        uint256 srcChainId = 1;
        extraData =
            abi.encode(Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT)))));

        bytes memory bytecode = abi.encodePacked(
            hex"608160113439333d60010152608134f3fe7f00000000000000000000000000000000000000000000000000000000000000003381146029575b005b3680600014607057602014603c575b6027565b60006044601c8280948135906370a0823183523060205260206040602486855afa5063a9059cbb83526020525af150386038565b5060008080809347905af15038603856",
            extraData
        );

        assembly ("memory-safe") {
            let ptr := mload(64)
            mstore(0, sload(user.slot))
            mstore(32, add(shl(32, 0), 1))

            let salt := keccak256(0, 64)

            mstore(0, add(shl(248, 0xff), shl(88, sload(entryPoint.slot))))
            mstore(21, salt)
            mstore(53, keccak256(add(bytecode, 32), mload(bytecode)))

            depositAddress := and(keccak256(0, 85), ADDRESS_MASK)

            mstore(64, ptr)
        }

        bytes memory message =
            abi.encode(depositAddress, user, nonce, srcChainId, address(1), token, 1000e18, extraData);

        Origin memory origin;

        LayerZeroFacet(address(entryPoint)).lzReceive({
            origin: origin,
            guid: bytes32(0),
            message: message,
            executor: address(0),
            extraData: extraData
        });
    }
}
