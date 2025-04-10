// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    ISignatureTransfer,
    SymbiosisFacet,
    ISymbiosisFacet,
    ISymbiosis,
    IEntryPoint,
    TransferHelper
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract SymbiosisFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDC, to: user, give: 1000e18 });

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
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

    function test_symbiosisFacet_sendSymbiosis_shouldTransferFromFromMsgSender() external {
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

        bytes memory finalSwapCalldata = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(
                        IMultiswapRouterFacet.multiswap2,
                        (
                            IMultiswapRouterFacet.Multiswap2Calldata({
                                amountInPercentages: Solarray.uint256s(1e18),
                                fullAmount: 0,
                                minAmountsOut: Solarray.uint256s(0),
                                tokenIn: USDC,
                                tokensOut: tokensOut,
                                pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                            })
                        )
                    ),
                    abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                )
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(USDC, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18 * (1_000_000 - 300) / 1_000_000);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            amount: 1000e18,
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

    function test_symbiosisFacet_sendSymbiosis_shouldTransferFromFromMsgSenderAfterSwap() external {
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

        bytes memory finalSwapCalldata = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(
                        IMultiswapRouterFacet.multiswap2,
                        (
                            IMultiswapRouterFacet.Multiswap2Calldata({
                                amountInPercentages: Solarray.uint256s(1e18),
                                fullAmount: 0,
                                minAmountsOut: Solarray.uint256s(0),
                                tokenIn: USDC,
                                tokensOut: tokensOut,
                                pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                            })
                        )
                    ),
                    abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                )
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(USDC, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18 * (1_000_000 - 300) / 1_000_000);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            amount: 1000e18,
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

    function test_symbiosisFacet_sendSymbiosis_shouldTransferFromViaPermit2() external {
        _resetPrank(user);

        IERC20(USDC).approve({ spender: contracts.permit2, amount: type(uint256).max });

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });

        bytes memory signature = _permit2Sign(
            userPk,
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({ token: USDC, amount: 1000e18 }),
                nonce: nonce,
                deadline: block.timestamp
            })
        );

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

        bytes memory finalSwapCalldata = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(
                        IMultiswapRouterFacet.multiswap2,
                        (
                            IMultiswapRouterFacet.Multiswap2Calldata({
                                amountInPercentages: Solarray.uint256s(1e18),
                                fullAmount: 0,
                                minAmountsOut: Solarray.uint256s(0),
                                tokenIn: USDC,
                                tokensOut: tokensOut,
                                pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                            })
                        )
                    ),
                    abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                )
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(USDC, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18 * (1_000_000 - 300) / 1_000_000);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(ITransferFacet.transferFromPermit2, (USDC, 1000e18, nonce, block.timestamp, signature)),
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            amount: 0,
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

    // =========================
    // no transfer revert
    // =========================

    function test_symbiosisFacet_sendSymbiosis_noTransferRevert() external {
        _resetPrank(user);

        deal({ token: USDC, to: address(entryPoint), give: 1000e18 });

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

        bytes memory finalSwapCalldata = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(
                        IMultiswapRouterFacet.multiswap2,
                        (
                            IMultiswapRouterFacet.Multiswap2Calldata({
                                amountInPercentages: Solarray.uint256s(1e18),
                                fullAmount: 0,
                                minAmountsOut: Solarray.uint256s(0),
                                tokenIn: USDC,
                                tokensOut: tokensOut,
                                pairs: Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_Cake))
                            })
                        )
                    ),
                    abi.encodeCall(ITransferFacet.transferToken, (user, tokensOut))
                )
            )
        );

        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    SymbiosisFacet.sendSymbiosis,
                    (
                        ISymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            amount: 1000e18,
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

    // =========================
    // receive
    // =========================

    address internal immutable bridge = 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8;

    function test_symbiosisFacet_receiveSymbiosis_shouldReceiveSymbiosis() external {
        _resetPrank(bridge);

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

        ISymbiosis(contracts.symbiosisPortal).metaUnsynthesize({
            _stableBridgingFee: 0.3e18,
            _crossChainID: bytes32(0),
            _externalID: bytes32(0),
            _to: user,
            _amount: 100e18,
            _rToken: USDC,
            _finalReceiveSide: address(entryPoint),
            _finalCalldata: multicallData,
            _finalOffset: 264
        });
    }

    function test_symbiosisFacet_receiveSymbiosis_shouldSendTokensToReceiverIfCallFailed() external {
        _resetPrank(bridge);

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 0;
        m2Data.tokenIn = USDC;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(ETH_USDT_UniV3_500));
        m2Data.tokensOut = Solarray.addresses(ETH);
        m2Data.minAmountsOut = Solarray.uint256s(0);
        m2Data.amountInPercentages = Solarray.uint256s(1e18);

        bytes memory multicallData = abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                    abi.encodeCall(ITransferFacet.transferToken, (user, m2Data.tokensOut))
                )
            )
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
            _finalOffset: 264
        });

        assertEq(IERC20(USDC).balanceOf({ account: address(entryPoint) }), 0);
    }
}
