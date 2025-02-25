// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    IERC20,
    BaseTest,
    Solarray,
    IOwnable,
    TransferHelper,
    MultiswapRouterFacet,
    IMultiswapRouterFacet,
    TransferFacet,
    ITransferFacet,
    ISignatureTransfer,
    console2,
    TransientStorageFacetLibrary
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapTest is BaseTest {
    using TransferHelper for address;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });

        _resetPrank(user);

        USDT.safeApprove({ spender: contracts.permit2, value: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    function test_multiswapRouterFacet_constructor_shouldInitializeInConstructor() external {
        MultiswapRouterFacet _multiswapRouterFacet =
            new MultiswapRouterFacet({ wrappedNative_: contracts.wrappedNative });
        TransferFacet _transferFacet =
            new TransferFacet({ wrappedNative: contracts.wrappedNative, permit2: contracts.permit2 });
        _transferFacet;

        assertEq(_multiswapRouterFacet.wrappedNative(), contracts.wrappedNative);
    }

    // =========================
    // transferFromPermit2
    // =========================

    function test_transferFacet_transferFromPermit2_shouldFailIfTokenNotApproved() external {
        _resetPrank(user);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });

        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 0 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        vm.expectRevert();
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 10_000e18, nonce, block.timestamp, signature))
            )
        });
    }

    function test_transferFacet_transferFromPermit2_shouldRevertIfTokenAmountIsZeroOrTransferFromFailed() external {
        _resetPrank(user);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });

        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 0 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        vm.expectRevert(ITransferFacet.TransferFacet_TransferFromFailed.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 0, nonce, block.timestamp, signature))
            )
        });
    }

    function test_transferFacet_transferFromPermit2_shouldTransferFrom257Times() external {
        _resetPrank(user);

        for (uint256 i; i < 257; ++i) {
            uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });

            bytes memory signature = _permit2Sign(
                userPk,
                ISignatureTransfer.PermitTransferFrom({
                    permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 1e18 }),
                    nonce: nonce,
                    deadline: block.timestamp
                })
            );

            entryPoint.multicall({
                data: Solarray.bytess(
                    abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 1e18, nonce, block.timestamp, signature))
                )
            });
        }
    }

    // =========================
    // multiswap
    // =========================

    function test_multiswapRouterFacet_multiswap_shouldRevertIfMultiswapDataIsInvalid() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });

        // amountIn is 0
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });

        // tokenIn is address(0) (native) and msg.value < amountIn
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.amountIn = 1;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });

        USDT.safeApprove({ spender: address(entryPoint), value: 100e18 });

        // tokenIn is not in sent pair
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000, WBNB_CAKE_CakeV3_500);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))) });
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV2Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
            Solarray.bytes32s(USDT_USDC_Cake, USDC_CAKE_Cake, BUSD_CAKE_Biswap, BUSD_ETH_Biswap, WBNB_ETH_Bakery);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        _resetPrank(user);
        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(WBNB.safeGetBalance({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV3Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(
            ETH_USDT_UniV3_500, WBNB_ETH_UniV3_500, WBNB_CAKE_UniV3_3000, WBNB_CAKE_CakeV3_500, WBNB_ETH_UniV3_3000
        );

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(ETH.safeGetBalance({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_failedV3Swap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        deal(USDC, user, 100e18);

        mData.amountIn = 100e18;
        mData.tokenIn = USDC;
        mData.pairs = Solarray.bytes32s(USDC_CAKE_UniV3_500);

        assertEq(quoter.multiswap({ data: mData }), 0);

        _resetPrank(user);
        USDC.safeApprove({ spender: address(entryPoint), value: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_failedV2Swap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
        // wrong pair fee
         Solarray.bytes32s(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE);

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_FailedV2Swap.selector);
        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    function test_multiswapRouterFacet_failedCallback() external {
        (, bytes memory data) =
            contracts.multiswapRouterFacet.call(abi.encodeWithSelector(TransferFacet.transferToken.selector));

        assertEq(bytes4(data), IMultiswapRouterFacet.MultiswapRouterFacet_SenderMustBeUniswapV3Pool.selector);
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfAmountOutLtMinAmountOut() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
            Solarray.bytes32s(USDT_USDC_Cake, USDC_CAKE_Cake, BUSD_CAKE_Biswap, BUSD_ETH_Biswap, WBNB_ETH_Bakery);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut + 1;

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldTransferAmountInToV2PairWhenBalanceIsGteAmountIn() external {
        deal(USDT, address(entryPoint), 100e18);

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
            Solarray.bytes32s(USDT_USDC_Cake, USDC_CAKE_Cake, BUSD_CAKE_Biswap, BUSD_ETH_Biswap, WBNB_ETH_Bakery);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut;

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    // =========================
    // multiswap with native
    // =========================

    function test_multiswapRouterFacet_multiswap_multiswapNative() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        deal({ to: user, give: 10e18 });

        mData.amountIn = 10e18;
        mData.tokenIn = address(0);
        mData.pairs =
            Solarray.bytes32s(WBNB_ETH_Bakery, BUSD_ETH_Biswap, BUSD_CAKE_Biswap, USDC_CAKE_Cake, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);

        uint256 userBalanceBefore = USDT.safeGetBalance({ account: user });

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(USDT.safeGetBalance({ account: user }) - userBalanceBefore, quoterAmountOut);
    }

    function test_multiswapRouterFacet_multiswap_swapToNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(USDT_USDC_Cake, BUSD_USDC_CakeV3_100, BUSD_CAKE_Cake, WBNB_CAKE_CakeV3_100);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
    }

    // =========================
    // multiswap with fee
    // =========================

    function test_multiswapRouterFacet_multiswap_shouldCalculateFee() external {
        _resetPrank(owner);
        quoter.setFeeContract({ newFeeContract: address(feeContract) });
        // 0.03%
        feeContract.setProtocolFee({ newProtocolFee: 300 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(
            ETH_USDT_UniV3_500, WBNB_ETH_UniV3_500, WBNB_CAKE_UniV3_3000, WBNB_CAKE_CakeV3_500, WBNB_ETH_UniV3_3000
        );

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut;

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: 100e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        _expectERC20TransferCall(ETH, address(feeContract), quoterAmountOut * 300 / (1e6 - 300));
        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000024,
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(ETH.safeGetBalance({ account: user }), quoterAmountOut);
        assertEq(feeContract.profit({ owner: address(feeContract), token: ETH }), quoterAmountOut * 300 / (1e6 - 300));
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_multiswap_noTransferRevert() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        deal({ token: USDT, to: address(entryPoint), give: 100e18 });

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(
            ETH_USDT_UniV3_500, WBNB_ETH_UniV3_500, WBNB_CAKE_UniV3_3000, WBNB_CAKE_CakeV3_500, WBNB_ETH_UniV3_3000
        );

        _resetPrank(user);

        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }
}
