// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IOwnable,
    TransferHelper,
    MultiswapRouterFacet,
    IMultiswapRouterFacet,
    TransferFacet,
    ITransferFacet,
    console,
    PoolHelper,
    IUniswapPool,
    HelperV3Lib,
    TransientStorageFacetLibrary,
    ISignatureTransfer
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract Multiswap2Test is BaseTest {
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

            address[] memory tokensOut = Solarray.addresses(USDT);

            entryPoint.multicall({
                data: Solarray.bytess(
                    abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 1e18, nonce, block.timestamp, signature)),
                    abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
                )
            });
        }
    }

    // =========================
    // multiswap2 without multicall
    // =========================

    function test_multiswapRouterFacet_multiswap2_withoutMulticall_shouldRevert() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(TransientStorageFacetLibrary.TransientStorageFacetLibrary_InvalidSenderAddress.selector);
        IMultiswapRouterFacet(address(entryPoint)).multiswap2({ data: m2Data });
    }

    // =========================
    // multiswap without transferToken
    // =========================

    function test_multiswapRouterFacet_multiswap2_withoutTransferToken_shouldRevert() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

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

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))
            )
        });
    }

    // =========================
    // multiswap2
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfMultiswap2DataIsInvalid()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.tokenIn = USDT;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // amountInPercentages array length and pairs length are not equal
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.55e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // tokensOut length check
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 1e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // fullAmountCheck
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.minAmountsOut = Solarray.uint256s(1e18);
        m2Data.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000), Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.56e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.55e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // amountIn is 0
        USDT.safeApprove({ spender: address(entryPoint), value: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        m2Data.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000), Solarray.bytes32s(USDT_USDC_Biswap));
        m2Data.minAmountsOut = Solarray.uint256s(0, 0);
        m2Data.amountInPercentages = Solarray.uint256s(1e18, 0);
        m2Data.tokensOut = Solarray.addresses(USDC, BUSD);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // tokenIn is address(0) (native) and msg.value < amountIn
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        m2Data.fullAmount = 1;
        m2Data.tokenIn = address(0);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        m2Data.minAmountsOut = Solarray.uint256s(0);
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });
    }

    function test_multiswapRouterFacet_failedV3Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDC;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_UniV3_500));
        m2Data.tokensOut = Solarray.addresses(CAKE);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        deal(USDC, user, 100e18);

        assertEq(quoter.multiswap2({ data: m2Data })[0], 0);

        _resetPrank(user);
        USDC.safeApprove({ spender: address(entryPoint), value: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_failedV2Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        deal(USDT, user, 100e18);

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
            data: Solarray.bytess(
                abi.encodeCall(TransferFacet.transferFromPermit2, (USDT, 100e18, nonce, block.timestamp, signature)),
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_failedCallback() external {
        (, bytes memory data) =
            contracts.multiswapRouterFacet.call(abi.encodeWithSelector(TransferFacet.transferToken.selector));

        assertEq(bytes4(data), IMultiswapRouterFacet.MultiswapRouterFacet_SenderMustBePool.selector);
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV2Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(USDC);

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });

        assertEq(IERC20(USDC).balanceOf({ account: user }), quoterAmountOut[0]);
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(WBNB);

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), quoterAmountOut[0]);
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfTokenNotTransferredFromContract() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(USDC);

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfAmountOutLtMinAmountOut()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] + 1);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(WBNB);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_multiswap2_partswapNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(WBNB, ETH))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        deal({ to: user, give: 10e18 });

        m2Data.fullAmount = 10e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.3e18, 0.1e18);
        m2Data.tokenIn = address(0);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000),
            Solarray.bytes32s(WBNB_ETH_Bakery)
        );
        m2Data.tokensOut = Solarray.addresses(ETH);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), m2Data.minAmountsOut[0]);
    }

    function test_multiswapRouterFacet_multiswap2_swapToNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.4e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_100),
            Solarray.bytes32s(WBNB_USDT_Biswap),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, m2Data.minAmountsOut[0]);
    }

    // =========================
    // multiswap2 with fee
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldCalculateFee()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        _resetPrank(owner);
        quoter.setRouter({ router: address(entryPoint) });
        // 0.03%
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.4e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_100),
            Solarray.bytes32s(WBNB_USDT_Biswap),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferCall(USDT, address(feeContract), m2Data.fullAmount * 300 / 1e6);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(feeContract.profit({ token: USDT }), m2Data.fullAmount * 300 / 1e6);
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_multiswap2_noTransferRevert()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        deal({ token: USDT, to: address(entryPoint), give: 100e18 });

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(address(0));
        m2Data.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    // =========================
    // partswap to several tokensOut
    // =========================

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOut()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOut_shouldReturnAmountInIfOneOfPairsArrayIsEmpty(
    )
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
    {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
        quoter.setRouter({ router: address(entryPoint) });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.3e18, 0.5e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake), Solarray.bytes32s(WBNB_USDT_Cake), new bytes32[](0)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, address(0));

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, USDT);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });

        uint256 balanceBefore = USDT.safeGetBalance({ account: user });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), 0);
        assertEq(balanceBefore - 500e18 - 500e18 * 300 / 1_000_000, USDT.safeGetBalance({ account: user }));
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: owner }), m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfOneOfTokensOutNotTransferFromContract()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfOneOfTokensOutNotInPaths()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapToERC20TokenAndNative()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        uint256 balanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - balanceBefore, m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }
}
