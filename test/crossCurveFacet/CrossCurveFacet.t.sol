// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";
import "../Helpers.t.sol";

contract CrossCurveFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDC, to: user, give: 100e18 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // startCrossCurve
    // =========================

    function test_crossCurveFacet_startCrossCurve_shouldStartCrossCurve() external checkStorage {
        // _resetPrank(user);

        // uint256 inputAmount = 100e18;

        // IEntryPoint.TokenTransfers memory tokenTransfers =
        //     IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(inputAmount) });

        // IERC20(USDC).approve({ spender: address(entryPoint), amount: inputAmount });

        // string[] memory ops = Solarray.strings("S", "LM", "S", "S", "BM");
        // bytes[] memory params = Solarray.bytess(
        //     hex"0000000000000000000000008ac76a51cc950d9822d68b83fe1ad97b32cd580d0000000000000000000000000000000000000000000000056bc75e2d63100000000000000000000000000000429c4c080bbc9e19bbc64c85ae2a14641c5e81630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a5e0e46462970c9ee8c2ecadcde254c483748ec40000000000000000000000000000000000000000000000055c4ef3cc58422bd000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000429c4c080bbc9e19bbc64c85ae2a14641c5e8163",
        //     hex"00000000000000000000000055d398326f99059ff775485246999027b3197955ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        //     hex"00000000000000000000000022677fdbdbf8648305a7f6cc409bd105b2f579f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f159c51297306839b7d44cbb5cb9360e4623ae5a0000000000000000000000000000000000000000000000054ee158e67724e1f2000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        //     hex"000000000000000000000000f1232a1ab5661abdd6e02c6d8ac9940a23bb0b84ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000440bcab62d629ba60ca56b80e565636e0c404e600000000000000000000000000000000000000000000000000000000005d5df1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000",
        //     hex"00000000000000000000000054e858c116f3d6bdf3c270f68cba96313b286577ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000017d5b07a0e6028edb638eb0a94c12ef7c73bcedb0000000000000000000000000000000000000000000000000000000000015aeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        // );
        // ICrossCurveRouter.Invoice memory receipt = ICrossCurveRouter.Invoice({
        //     executionPrice: 65_734_964_737_465,
        //     deadline: 1_753_175_196,
        //     v: 28,
        //     r: 0x0bda422808c8544c6aa1794ddc3da0a21251c223ed677278064864f6a80ba786,
        //     s: 0x6b4ff1f5aebd2522adcc552c8fe8afb3856146efae3da5ab1fb6501b13faf088
        // });

        // _expectERC20TransferFromCall(USDC, user, address(entryPoint), inputAmount);
        // _expectERC20ApproveCall(USDC, contracts.crossCurveUnifiedRouter, inputAmount);
        // entryPoint.multicall{ value: receipt.executionPrice }({
        //     tokenTransfers: tokenTransfers,
        //     data: Solarray.bytess(
        //         abi.encodeCall(CrossCurveFacet.startCrossCurve, (ops, params, receipt)),
        //         abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(USDC)))
        //     )
        // });
    }

    // function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositWithNativeCurrency() external checkStorage {
    //     _resetPrank(user);

    //     uint256 inputAmount = 1000e18;

    //     bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool);

    //     entryPoint.multicall{ value: inputAmount }({
    //         tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
    //         data: Solarray.bytess(
    //             abi.encodeCall(
    //                 AcrossFacet.sendAcrossDepositV3,
    //                 (
    //                     IAcrossFacet.V3AcrossDepositParams({
    //                         recipient: address(entryPoint),
    //                         inputToken: address(0), // WETH
    //                         outputToken: outputTokenWETH,
    //                         outputAmountPercent: outputAmountPercentage,
    //                         destinationChainId: dstChainId,
    //                         exclusiveRelayer: address(0),
    //                         quoteTimestamp: uint32(block.timestamp),
    //                         fillDeadline: uint32(block.timestamp + 3600),
    //                         exclusivityDeadline: 0,
    //                         message: message
    //                     })
    //                 )
    //             )
    //         )
    //     });

    //     assertEq(user.balance, 0);
    // }

    // address constant tokenForSwap = 0xF19308F923582A6f7c465e5CE7a9Dc1BEC6665B1;
    // bytes32 constant poolForSwap = 0x800000000000000000000000c45A81BC23A64eA556ab4CdF08A86B61cdcEEA8b;

    // function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositAfterSwap() external checkStorage {
    //     deal({ token: tokenForSwap, to: user, give: 1000e18 });

    //     IMultiswapRouterFacet.MultiswapCalldata memory mData;

    //     mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: tokenForSwap, amount: 1 }));
    //     mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(poolForSwap, 1e18)));
    //     mData.tokensOut = Solarray.addresses(inputTokenWETH);

    //     IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
    //         tokens: Solarray.addresses(tokenForSwap),
    //         amounts: Solarray.uint256s(1000e18)
    //     });

    //     mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

    //     _resetPrank(user);

    //     IERC20(tokenForSwap).approve({ spender: address(entryPoint), amount: 1000e18 });

    //     uint256 inputAmount = mData.minAmountsOut[0];

    //     bytes memory message = _getMessage(optimismUniswapV3_WETH_OP_Pool);

    //     _expectERC20ApproveCall(inputTokenWETH, contracts.acrossSpokePool, inputAmount);
    //     entryPoint.multicall({
    //         tokenTransfers: tokenTransfers,
    //         data: Solarray.bytess(
    //             abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
    //             abi.encodeCall(
    //                 AcrossFacet.sendAcrossDepositV3,
    //                 (
    //                     IAcrossFacet.V3AcrossDepositParams({
    //                         recipient: address(entryPoint),
    //                         inputToken: inputTokenWETH, // WETH
    //                         outputToken: outputTokenWETH,
    //                         outputAmountPercent: outputAmountPercentage,
    //                         destinationChainId: dstChainId,
    //                         exclusiveRelayer: address(0),
    //                         quoteTimestamp: uint32(block.timestamp),
    //                         fillDeadline: uint32(block.timestamp + 3600),
    //                         exclusivityDeadline: 0,
    //                         message: message
    //                     })
    //                 )
    //             )
    //         )
    //     });
    // }

    // // =========================
    // // helper
    // // =========================

    // address constant OP_TOKEN = 0x4200000000000000000000000000000000000042;

    // function _getMessage(bytes32 pool) internal view returns (bytes memory) {
    //     IMultiswapRouterFacet.MultiswapCalldata memory mData;

    //     if (pool == optimismUniswapV3_USDC_OP_Pool) {
    //         mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: inputTokenUSDC, amount: 1 }));
    //     } else {
    //         mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: outputTokenWETH, amount: 1 }));
    //     }
    //     mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pool));
    //     mData.tokensOut = Solarray.addresses(OP_TOKEN);
    //     mData.minAmountsOut = Solarray.uint256s(0);

    //     return abi.encodeWithSignature(
    //         "multicall(bytes[])",
    //         Solarray.bytess(
    //             abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
    //             abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
    //         )
    //     );
    // }
}
