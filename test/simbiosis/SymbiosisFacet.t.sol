// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract SymbiosisFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDC, to: user, give: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    function test_symbiosisFacet_constructor_shouldSetPortalAddress() external {
        SymbiosisFacet _symbiosisFacet = new SymbiosisFacet({ portal_: contracts.symbiosisPortal });

        assertEq(_symbiosisFacet.portal(), contracts.symbiosisPortal);
    }

    // =========================
    // sendSymbiosis
    // =========================

    function test_symbiosisFacet_sendSymbiosis() external {
        _resetPrank(user);

        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        bytes memory secondSwapCalldata = abi.encodeCall(
            ISymbiosis.multicall,
            (
                1000e18,
                Solarray.bytess(
                    abi.encodeCall(
                        ISymbiosis.swap,
                        (
                            3,
                            10,
                            1000e18 - 0.3e18,
                            997e6,
                            0xcB28fbE3E9C0FEA62E0E63ff3f232CECfE555aD4,
                            block.timestamp + 1200
                        )
                    )
                ),
                Solarray.addresses(0x6148FD6C649866596C3d8a971fC313E5eCE84882),
                Solarray.addresses(
                    0x5e19eFc6AC9C80bfAA755259c9fab2398A8E87eB, 0x59AA2e5F628659918A4890A2a732E6C8bD334E7A
                ),
                Solarray.uint256s(100),
                0x2cBABD7329b84e2c0A317702410E7c73D0e0246d
            )
        );

        address[] memory tokensOut = Solarray.addresses(CAKE);

        bytes memory finalSwapCalldata = abi.encodeWithSignature(
            "multicall((address[],uint256[]),bytes[])",
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(997e6) }),
            Solarray.bytess(
                abi.encodeCall(
                    MultiswapRouterFacet.multiswap,
                    (
                        IMultiswapRouterFacet.MultiswapCalldata({
                            tokensIn: Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 })),
                            minAmountsOut: Solarray.uint256s(0),
                            tokensOut: tokensOut,
                            pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                        })
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDC),
                amounts: Solarray.uint256s(1000e18)
            }),
            data: Solarray.bytess(
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            rtoken: USDC,
                            chain2address: user,
                            swapTokens: Solarray.addresses(
                                0x5e19eFc6AC9C80bfAA755259c9fab2398A8E87eB, 0x59AA2e5F628659918A4890A2a732E6C8bD334E7A
                            ),
                            secondSwapCalldata: secondSwapCalldata,
                            finalReceiveSide: address(entryPoint),
                            finalCalldata: finalSwapCalldata,
                            finalOffset: 232
                        })
                    )
                )
            )
        });
    }

    function test_symbiosisFacet_sendSymbiosis_shouldSendAfterSwap() external {
        deal({ token: USDT, to: user, give: 1000e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.tokensOut = Solarray.addresses(USDC, CAKE);
        mData.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(USDT_CAKE_Cake, 1e18)), new bytes32[](0));

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        bytes memory secondSwapCalldata = abi.encodeCall(
            ISymbiosis.multicall,
            (
                1000e18,
                Solarray.bytess(
                    abi.encodeCall(
                        ISymbiosis.swap,
                        (
                            3,
                            10,
                            1000e18 - 0.3e18,
                            997e6,
                            0xcB28fbE3E9C0FEA62E0E63ff3f232CECfE555aD4,
                            block.timestamp + 1200
                        )
                    )
                ),
                Solarray.addresses(0x6148FD6C649866596C3d8a971fC313E5eCE84882),
                Solarray.addresses(
                    0x5e19eFc6AC9C80bfAA755259c9fab2398A8E87eB, 0x59AA2e5F628659918A4890A2a732E6C8bD334E7A
                ),
                Solarray.uint256s(100),
                0x2cBABD7329b84e2c0A317702410E7c73D0e0246d
            )
        );

        address[] memory tokensOut = Solarray.addresses(CAKE);

        bytes memory finalSwapCalldata = abi.encodeWithSignature(
            "multicall((address[],uint256[]),bytes[])",
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(997e6) }),
            Solarray.bytess(
                abi.encodeCall(
                    MultiswapRouterFacet.multiswap,
                    (
                        IMultiswapRouterFacet.MultiswapCalldata({
                            tokensIn: Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 })),
                            minAmountsOut: Solarray.uint256s(0),
                            tokensOut: tokensOut,
                            pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                        })
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
            )
        );

        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            rtoken: USDC,
                            chain2address: user,
                            swapTokens: Solarray.addresses(
                                0x5e19eFc6AC9C80bfAA755259c9fab2398A8E87eB, 0x59AA2e5F628659918A4890A2a732E6C8bD334E7A
                            ),
                            secondSwapCalldata: secondSwapCalldata,
                            finalReceiveSide: address(entryPoint),
                            finalCalldata: finalSwapCalldata,
                            finalOffset: 232
                        })
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(CAKE)))
            )
        });
    }

    // =========================
    // receive
    // =========================

    address internal immutable bridge = 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8;

    function test_symbiosisFacet_receiveSymbiosis_shouldReceiveSymbiosis() external {
        _resetPrank(bridge);

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.tokensOut = Solarray.addresses(CAKE, USDT, BUSD);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDC_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Cake, 0.2e18),
                _encodePercentageInPool(BUSD_USDC_CakeV3_100, 0.6e18)
            )
        );

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(97e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall((address[],uint256[]),bytes[])",
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(0) }),
            Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(ITransferFacet.transferToken, (user, mData.tokensOut))
            )
        );

        ISymbiosis(contracts.symbiosisPortal).metaUnsynthesize({
            _stableBridgingFee: 0.3e18,
            _crossChainID: bytes32(0),
            _externalID: bytes32(0),
            _to: user,
            _amount: 100e18,
            _rToken: USDC,
            _finalReceiveSide: address(entryPoint),
            _finalCalldata: multicallData,
            _finalOffset: 260
        });
    }

    function test_symbiosisFacet_receiveSymbiosis_shouldSendTokensToReceiverIfCallFailed() external {
        _resetPrank(bridge);

        bytes memory multicallData = abi.encodeWithSignature(
            "multicall(bytes[])",
            (Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDC)))))
        );

        _expectERC20TransferCall(USDC, user, 99.7e18);
        ISymbiosis(contracts.symbiosisPortal).metaUnsynthesize({
            _stableBridgingFee: 0.3e18,
            _crossChainID: bytes32(0),
            _externalID: bytes32(0),
            _to: user,
            _amount: 100e18,
            _rToken: USDC,
            _finalReceiveSide: address(entryPoint),
            _finalCalldata: multicallData,
            _finalOffset: 260
        });

        assertEq(IERC20(USDC).balanceOf({ account: address(entryPoint) }), 0);
    }
}
