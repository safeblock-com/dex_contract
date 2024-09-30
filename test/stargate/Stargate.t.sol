// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    StargateFacet,
    IStargateFacet,
    TransferHelper
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract StargateFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: WBNB, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    function test_stargateFacet_constructor_shouldInitializeInConstructor() external {
        StargateFacet _stargateFacet = new StargateFacet({ endpointV2: contracts.endpointV2 });

        assertEq(_stargateFacet.lzEndpoint(), contracts.endpointV2);
    }

    // =========================
    // unwrapNative
    // =========================

    function test_transferFacet_unwrapNative_shouldUnwrapNativeToken() external {
        deal({ token: WBNB, to: address(entryPoint), give: 10e18 });

        _resetPrank(user);

        assertEq(IERC20(WBNB).balanceOf({ account: address(entryPoint) }), 10e18);
        assertEq(address(entryPoint).balance, 0);

        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(ITransferFacet.unwrapNative, (5e18))) });

        assertEq(IERC20(WBNB).balanceOf({ account: address(entryPoint) }), 5e18);
        assertEq(address(entryPoint).balance, 5e18);

        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(ITransferFacet.unwrapNative, (5e18))) });

        assertEq(IERC20(WBNB).balanceOf({ account: address(entryPoint) }), 0);
        assertEq(address(entryPoint).balance, 10e18);
    }

    // =========================
    // sendStargateV2
    // =========================

    uint32 dstEidV2 = 30_101;
    address stargatePool = 0x138EB30f73BC423c6455C53df6D89CB01d9eBc63;

    function test_stargateFacet_sendStargateV2_shouldSendStargateV2() external {
        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 fee, uint256 amountOut) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 1000e18,
            composer: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        assertApproxEqAbs(amountOut, 1000e18, 1000e18 * 0.997e18 / 1e18);

        entryPoint.multicall{ value: fee }({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 1000e18, user, 0, bytes(""))),
                abi.encodeCall(ITransferFacet.transferToken, (USDT, 0, user))
            )
        });
    }

    function test_stargateFacet_sendStargateV2_shouldRevertIfNativeBalanceNotEnough() external {
        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 1000e18,
            composer: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        vm.expectRevert(IStargateFacet.StargateFacet_InvalidNativeBalance.selector);
        entryPoint.multicall{ value: fee >> 1 }({
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 1000e18, user, 0, bytes("")))
            )
        });
    }

    function test_stargateFacet_sendStargateV2_shouldRevertIfTransferFromError() external {
        _resetPrank(user);

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 1000e18,
            composer: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall{ value: fee }({
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 1000e18, user, 0, bytes("")))
            )
        });

        deal({ token: USDT, to: user, give: 1000e18 });

        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall{ value: fee }({
            data: Solarray.bytess(
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 1000e18, user, 0, bytes("")))
            )
        });
    }

    // =========================
    // sendStargate with multiswap
    // =========================

    function test_stargateFacet_sendStargateWithMultiswap_shouldSendStargateV2WithMultiswap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 10e18;
        mData.tokenIn = WBNB;
        mData.pairs =
            Solarray.bytes32s(WBNB_ETH_Bakery, BUSD_ETH_Biswap, BUSD_CAKE_Biswap, USDC_CAKE_Cake, USDT_USDC_Cake);

        _resetPrank(user);

        IERC20(WBNB).approve({ spender: address(entryPoint), amount: 1000e18 });

        uint256 quoteMultiswap = quoter.multiswap({ data: mData });

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: quoteMultiswap,
            composer: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        entryPoint.multicall{ value: fee }({
            replace: 0x0000000000000000000000000000000000000000000000000000000000240044,
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 0, user, 0, bytes(""))),
                abi.encodeCall(ITransferFacet.transferToken, (USDT, 0, user))
            )
        });

        assertEq(IERC20(USDT).balanceOf({ account: address(entryPoint) }), 0);
    }
}
