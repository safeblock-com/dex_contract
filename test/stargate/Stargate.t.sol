// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract StargateFacetTest is BaseTest {
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
    // constructor
    // =========================

    function test_stargateFacet_constructor_shouldInitializeInConstructor() external {
        StargateFacet _stargateFacet = new StargateFacet({ endpointV2: contracts.layerZeroEndpointV2 });

        assertEq(_stargateFacet.lzEndpoint(), contracts.layerZeroEndpointV2);
    }

    // =========================
    // sendStargateV2
    // =========================

    uint32 dstEidV2 = 30_101;
    address stargatePool = 0x138EB30f73BC423c6455C53df6D89CB01d9eBc63;

    function test_stargateFacet_sendStargateV2_shouldSendStargateV2() external checkStorage {
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

        assertApproxEqAbs(amountOut, 1000e18, 1000e18 * 0.997e18 / 1e18);

        address[] memory tokensOut = Solarray.addresses(USDT);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDT, stargatePool, 1000e18);
        entryPoint.multicall{ value: fee }({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDT),
                amounts: Solarray.uint256s(1000e18)
            }),
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, user, 0, bytes(""))),
                abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_stargateFacet_sendStargateV2_shouldRevertIfNativeBalanceNotEnough() external checkStorage {
        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 1000e18,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        vm.expectRevert(abi.encodeWithSelector(Utils.ValueLowerThanExpected.selector, fee >> 1, fee));
        entryPoint.multicall{ value: fee >> 1 }({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDT),
                amounts: Solarray.uint256s(1000e18)
            }),
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, user, 0, bytes("")))
            )
        });
    }

    // =========================
    // sendStargate with multiswap
    // =========================

    function test_stargateFacet_sendStargateWithMultiswap_shouldSendStargateV2WithMultiswap() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.tokensOut = Solarray.addresses(USDT);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Cake, 1e18)));

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(1000e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: mData.minAmountsOut[0],
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDT, stargatePool, mData.minAmountsOut[0]);
        entryPoint.multicall{ value: fee }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, user, 0, bytes(""))),
                abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT)))
            )
        });

        assertEq(IERC20(USDT).balanceOf({ account: address(entryPoint) }), 0);
    }

    address stargatePool_2 = 0x77b2043768d28E9C9aB44E1aBfC95944bcE57931;
    uint16 dstEidV2_2 = 30_110;

    function test_stargateFacet_sendStargateNative_shouldRevertIfSendStargateWithNativePool() external checkStorage {
        vm.createSelectFork(vm.rpcUrl("ethereum_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ to: user, give: 1000e18 });

        _resetPrank(user);

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool_2,
            dstEid: dstEidV2_2,
            amountLD: 0.111111111111111111e18,
            receiver: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        assertGt(fee, 0.111111111111111111e18);

        vm.expectRevert(IStargateFacet.StargateFacet_UnsupportedAsset.selector);
        entryPoint.multicall{ value: fee }({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool_2, dstEidV2_2, user, 0, bytes("")))
            )
        });

        assertEq(address(entryPoint).balance, 0);
    }
}
