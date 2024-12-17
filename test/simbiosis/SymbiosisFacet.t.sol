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
    IEntryPoint
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract SymbiosisFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

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

        bytes memory finalSwapCalldata = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(
                    IMultiswapRouterFacet.multiswap,
                    (
                        IMultiswapRouterFacet.MultiswapCalldata({
                            amountIn: 0,
                            minAmountOut: 0,
                            tokenIn: USDC,
                            pairs: Solarray.bytes32s(USDC_CAKE_Cake)
                        })
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (CAKE, 0, user))
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18);
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

        bytes memory finalSwapCalldata = abi.encodeWithSignature(
            "multicall(bytes32,bytes[])",
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(
                    IMultiswapRouterFacet.multiswap,
                    (
                        IMultiswapRouterFacet.MultiswapCalldata({
                            amountIn: 0,
                            minAmountOut: 0,
                            tokenIn: USDC,
                            pairs: Solarray.bytes32s(USDC_CAKE_Cake)
                        })
                    )
                ),
                abi.encodeCall(ITransferFacet.transferToken, (CAKE, 0, user))
            )
        );

        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20ApproveCall(USDC, contracts.symbiosisPortal, 1000e18);
        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000000000044,
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
}
