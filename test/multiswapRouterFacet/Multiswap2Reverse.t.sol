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

contract Multiswap2ReverseTest is BaseTest {
    using TransferHelper for address;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        _resetPrank(user);
        USDT.safeApprove({ spender: contracts.permit2, value: type(uint256).max });
    }

    // =========================
    // multiswap2Reverse without multicall
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_withoutMulticall_shouldRevert() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(USDC)));
        m2Data.minAmountsOut =
            Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC), _getReserveOut(USDT_USDC_Cake, USDC));

        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake));
        m2Data.tokensOut = Solarray.addresses(USDC, USDC);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        vm.expectRevert(TransientStorageFacetLibrary.TransientStorageFacetLibrary_InvalidSenderAddress.selector);
        IMultiswapRouterFacet(address(entryPoint)).multiswap2Reverse({ data: m2Data });
    }

    // =========================
    // multiswap2Reverse without transferToken
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_withoutTransferToken_shouldRevert() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(USDC)));
        m2Data.minAmountsOut =
            Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC), _getReserveOut(USDT_USDC_Cake, USDC));

        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake));
        m2Data.tokensOut = Solarray.addresses(USDC, USDC);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDT, amount: m2Data.fullAmount }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    TransferFacet.transferFromPermit2, (USDT, m2Data.fullAmount, nonce, block.timestamp, signature)
                ),
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))
            )
        });
    }

    // =========================
    // multiswap2Reverse
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_shouldRevertIfMultiswap2DataIsInvalid()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        // tokensOut array length is not equal to pairs array length
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_UniV3_100));
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        // minAmountsOut array length is not equal to pairs array length
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_UniV3_100));
        m2Data.tokensOut = Solarray.addresses(USDC);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        // not approved
        m2Data.minAmountsOut = Solarray.uint256s(1e18);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(USDC)));
        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        // amountIn is 0
        USDT.safeApprove({ spender: address(entryPoint), value: m2Data.fullAmount });

        // amountInPercentages (actual tokensOut) length is zero or token not swapped
        m2Data.amountInPercentages = new uint256[](0);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        m2Data.fullAmount = 0;
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });

        // tokenIn is address(0) (native) and msg.value < amountIn
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(WBNB_USDT_CakeV3_500));
        m2Data.tokenIn = address(0);
        m2Data.minAmountsOut = Solarray.uint256s(1e18);
        m2Data.tokensOut = Solarray.addresses(USDT);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(USDT)));
        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        vm.expectRevert();
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_failedV3Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDC;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(CAKE)));
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_UniV3_500));
        m2Data.tokensOut = Solarray.addresses(CAKE);
        m2Data.minAmountsOut = Solarray.uint256s(1e18);

        deal({ token: USDC, to: user, give: 100e18 });

        assertEq(quoter.multiswap2Reverse({ data: m2Data }), type(uint256).max);

        _resetPrank(user);
        USDC.safeApprove({ spender: address(entryPoint), value: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_failedV2Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.minAmountsOut = Solarray.uint256s(0.1e18);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

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
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldSwapThroughAllUniswapV2Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(USDC)));
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC, USDC);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        address[] memory tokensOut = Solarray.addresses(USDC);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(USDC, user, 3e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldSwapThroughAllUniswapV3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(WBNB, user, 6e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldSwapThroughAllUniswapV3PairsWithRemainingAmountIn()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data }) + 100e18;

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(WBNB, user, 6e18);
        _expectERC20TransferCall(USDT, user, 100e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldRevertIfTokenNotTransferredFromContract() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data))) });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldRevertIfAmountInGtFullAmount()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data }) - 1;

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        vm.expectRevert(TransferHelper.TransferHelper_TransferError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_partswapNativeThroughV2V3PairsWithRemainingAmountIn()
        external
        checkTokenStorage(Solarray.addresses(WBNB, ETH))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = address(0);
        m2Data.minAmountsOut = Solarray.uint256s(0.1e18, 0.05e18, 0.05e18, 0.05e18);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(ETH)));
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000)
        );
        m2Data.tokensOut = Solarray.addresses(ETH, ETH, ETH, ETH);

        uint256 quoterAmountIn = quoter.multiswap2Reverse({ data: m2Data });

        m2Data.fullAmount = quoterAmountIn + 100e18;

        deal({ to: user, give: m2Data.fullAmount });
        _resetPrank(user);

        uint256 balanceBefore = user.balance;

        entryPoint.multicall{ value: m2Data.fullAmount }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(balanceBefore - user.balance, quoterAmountIn);
        assertEq(IERC20(ETH).balanceOf({ account: user }), 0.1e18 + 0.05e18 + 0.05e18 + 0.05e18);
    }

    function test_multiswapRouterFacet_multiswap2Reverse_partswapNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(WBNB, ETH))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = address(0);
        m2Data.minAmountsOut = Solarray.uint256s(0.1e18, 0.05e18, 0.05e18, 0.05e18);
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(ETH)));
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000)
        );
        m2Data.tokensOut = Solarray.addresses(ETH, ETH, ETH, ETH);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        deal({ to: user, give: m2Data.fullAmount });
        _resetPrank(user);

        entryPoint.multicall{ value: m2Data.fullAmount }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), 0.1e18 + 0.05e18 + 0.05e18 + 0.05e18);
    }

    function test_multiswapRouterFacet_multiswap2Reverse_swapToNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, 6e18);
    }

    // =========================
    // multiswap2 with fee
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_shouldCalculateFee()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        _resetPrank(owner);
        quoter.setRouter({ router: address(entryPoint) });
        // 0.03%
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferCall(USDT, address(feeContract), m2Data.fullAmount * 1e6 / (1e6 + 300) * 300 / 1e6);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(feeContract.profit({ token: USDT }), m2Data.fullAmount * 1e6 / (1e6 + 300) * 300 / 1e6);
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_noTransferRevert()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(WBNB)));
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    // =========================
    // partswap to several tokensOut via multiswap2Reverse
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_partswapToSeveralTokensOut_shouldReturnAmountOutIfOneOfPairsArrayIsEmpty(
    )
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
    {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
        quoter.setRouter({ router: address(entryPoint) });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.minAmountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        m2Data.amountInPercentages = Solarray.uint256s(
            uint256(uint160(CAKE)), uint256(uint160(USDC)), uint256(uint160(WBNB)), uint256(uint160(USDT))
        );
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            new bytes32[](0)
        );
        m2Data.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, USDT);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, USDC, CAKE)))
            )
        });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(USDC, user, 1e18);
        _expectERC20TransferCall(WBNB, user, 0.1e18);
        _expectERC20TransferCall(USDT, user, 0.05e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.minAmountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        m2Data.amountInPercentages =
            Solarray.uint256s(uint256(uint160(CAKE)), uint256(uint160(USDC)), uint256(uint160(WBNB)));
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(USDC, user, 1e18);
        _expectERC20TransferCall(WBNB, owner, 0.15e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldRevertIfOneOfTokensOutNotInPaths()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.minAmountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        m2Data.amountInPercentages =
            Solarray.uint256s(uint256(uint160(CAKE)), uint256(uint160(USDC)), uint256(uint160(WBNB)));
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(CAKE)), uint256(uint160(USDC)));

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, USDC, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2Reverse_shouldSwapToERC20TokenAndNative()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.minAmountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        m2Data.amountInPercentages =
            Solarray.uint256s(uint256(uint160(CAKE)), uint256(uint160(USDC)), uint256(uint160(WBNB)));
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, WBNB);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: USDT, to: user, give: m2Data.fullAmount });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        uint256 balanceBefore = user.balance;

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(USDC, user, 1e18);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - balanceBefore, 0.15e18);
    }

    // =================================================
    // helpers
    // =================================================

    function _getReserveOut(bytes32 pair, address tokenOut) private view returns (uint256) {
        IUniswapPool _pair = IUniswapPool(address(uint160(uint256(pair))));

        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        address token0 = _pair.token0();

        if (token0 == tokenOut) {
            return (reserve0 > 0 ? (reserve0 >> 1) : 0);
        } else {
            return (reserve1 > 0 ? (reserve1 >> 1) : 0);
        }
    }
}
