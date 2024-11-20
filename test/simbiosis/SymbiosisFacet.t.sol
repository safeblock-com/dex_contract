// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    SymbiosisFacet,
    ISymbiosis,
    TransferHelper
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract SymbiosisFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDC, to: user, give: 1000e18 });
        deal({ token: BUSD, to: user, give: 1000e18 });
        deal({ token: WBNB, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    // =========================
    // send
    // =========================

    function test_symboisisFacet_send() external {
        _resetPrank(user);

        IERC20(USDC).transfer({ to: address(entryPoint), amount: 1000e18 });

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

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    SymbiosisFacet.send,
                    (
                        SymbiosisFacet.SymbiosisTransaction({
                            stableBridgingFee: 0.3e18,
                            amount: 1000e18,
                            rtoken: USDC,
                            chain2address: user,
                            swapTokens: Solarray.addresses(
                                0x5e19eFc6AC9C80bfAA755259c9fab2398A8E87eB, 0x59AA2e5F628659918A4890A2a732E6C8bD334E7A
                            ),
                            secondSwapCalldata: secondSwapCalldata,
                            finalReceiveSide: address(entryPoint),
                            finalCalldata: bytes(""),
                            finalOffset: 0 // TODO
                         })
                    )
                )
            )
        });
    }
}
