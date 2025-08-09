// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: USDC, to: user, give: 1000e18 });
        deal({ token: WBNB, to: user, give: 1000e18 });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: contracts.permit2, amount: 1000e18 });
        IERC20(USDC).approve({ spender: contracts.permit2, amount: 1000e18 });
        IERC20(WBNB).approve({ spender: contracts.permit2, amount: 1000e18 });
    }

    // =========================
    // multiswap with permit2
    // =========================

    function test_multiswapRouterFacet_multiswapPermit2_shouldSwap123() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 }),
            Utils.encodeTokenAndAmount({ token: USDT, amount: 2 }),
            Utils.encodeTokenAndAmount({ token: CAKE, amount: 2 })
        );
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_CakeV3_100, 0.1e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.9e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Cake, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(USDT_CAKE_Cake, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(WBNB_CAKE_UniV3_3000, 1e18))
        );

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(100e18, 100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 100e18);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_shouldSwapThroughAllUniswapV2Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(USDC);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_USDC_Biswap, 0.25e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.25e18),
                _encodePercentageInPool(USDT_USDC_Cake, 0.25e18)
            )
        );

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_shouldSwapThroughAllUniswapV3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_shouldRevertIfAmountOutLtMinAmountOut() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = Solarray.uint256s(
            quoter.multiswap({
                tokenTransfers: IEntryPoint.TokenTransfers({
                    tokens: tokenTransfersPermit2.tokens,
                    amounts: tokenTransfersPermit2.amounts
                }),
                data: mData
            })[0] + 1
        );

        _resetPrank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                IErrors.ValueLowerThanExpected.selector, mData.minAmountsOut[0] - 1, mData.minAmountsOut[0]
            )
        );
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_swapToNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.1e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_100, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Biswap, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.4e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_partswapToSeveralTokensOut() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.3e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_partswapFromSeveralTokensIn() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(BUSD_USDC_CakeV3_100, 1e18))
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, BUSD);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 1000e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(BUSD, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_partswapToSeveralTokensOut_shouldReturnAmountInIfOneOfPairsArrayIsEmpty(
    )
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.4e18), _encodePercentageInPool(WBNB_USDT_Cake, 0.6e18)
            ),
            new bytes32[](0)
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(100e18, 100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.3e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, owner, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapPermit2_shouldSwapToERC20TokenAndNative() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.2e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(BUSD_USDC_Cake, 1e18))
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, BUSD);

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(100e18, 100e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: address(0),
            feeAmount: 0
        });

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk, tokenTransfersPermit2.tokens, tokenTransfersPermit2.amounts, nonce, deadline, bytes32(0)
        );

        mData.minAmountsOut = quoter.multiswap({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: tokenTransfersPermit2.tokens,
                amounts: tokenTransfersPermit2.amounts
            }),
            data: mData
        });

        _resetPrank(user);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(BUSD, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, BUSD))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }
}
