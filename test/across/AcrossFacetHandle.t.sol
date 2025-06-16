// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    AcrossFacet,
    IAcrossFacet,
    TransferHelper,
    IEntryPoint,
    TransferFacet
} from "../BaseTest.t.sol";

import { E18 } from "../../src/libraries/Constants.sol";

contract AcrossFacetHandleTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("optimism_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: outputTokenUSDC, to: address(entryPoint), give: 1000e6 });
        deal({ token: outputTokenWETH, to: address(entryPoint), give: 1000e18 });

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
    }

    // =========================
    // handleV3AcrossMessage
    // =========================

    bytes32 constant optimismUniswapV3_USDC_OP_Pool = 0x800000000000000000000000B533c12fB4e7b53b5524EAb9b47d93fF6C7A456F;
    bytes32 constant optimismUniswapV3_WETH_OP_Pool = 0x80000000000000000000000068F5C0A2DE713a54991E01858Fd27a3832401849;

    uint32 constant dstChainId = 10; // optimism
    address constant inputTokenWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant outputTokenWETH = 0x4200000000000000000000000000000000000006;
    address constant inputTokenUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant outputTokenUSDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    function test_acrossFacet_handleV3AcrossMessage_shouldRevertIfSenderIsNotSpokePool() external {
        _resetPrank(user);

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, 1000e6, false);

        vm.expectRevert(IAcrossFacet.AcrossFacet_NotSpokePool.selector);
        IAcrossFacet(address(entryPoint)).handleV3AcrossMessage({
            tokenSent: outputTokenUSDC,
            amount: 1000e6,
            relayer: address(0),
            message: abi.encode(user, message)
        });
    }

    function test_acrossFacet_handleV3AcrossMessage_shouldCallMessageFromCall()
        external
        checkTokenStorage(Solarray.addresses(OP_TOKEN, outputTokenUSDC))
    {
        _resetPrank(contracts.acrossSpokePool);

        assertEq(TransferHelper.safeGetBalance({ token: outputTokenUSDC, account: address(entryPoint) }), 1000e6);

        IAcrossFacet(address(entryPoint)).handleV3AcrossMessage({
            tokenSent: outputTokenUSDC,
            amount: 1000e6,
            relayer: address(0),
            message: abi.encode(user, _getMessage(optimismUniswapV3_USDC_OP_Pool, 1000e6, false))
        });

        assertEq(TransferHelper.safeGetBalance({ token: outputTokenUSDC, account: address(entryPoint) }), 0);
    }

    event CallFailed(bytes errorMessage);

    function test_acrossFacet_handleV3AcrossMessage_shouldEmitCallFailedIfMessageFails()
        external
        checkTokenStorage(Solarray.addresses(OP_TOKEN, outputTokenUSDC))
    {
        _resetPrank(contracts.acrossSpokePool);

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, 1000e6, true);

        uint256 quoterAmountOut;
        assembly {
            quoterAmountOut := mload(0)
        }

        vm.expectEmit();
        emit CallFailed({
            errorMessage: abi.encodeWithSelector(
                IMultiswapRouterFacet.MultiswapRouterFacet_ValueLowerThanExpected.selector,
                quoterAmountOut,
                quoterAmountOut * 2
            )
        });
        _expectERC20TransferCall(outputTokenUSDC, user, 1000e6);
        IAcrossFacet(address(entryPoint)).handleV3AcrossMessage({
            tokenSent: outputTokenUSDC,
            amount: 1000e6,
            relayer: address(0),
            message: abi.encode(user, message)
        });
    }

    // =========================
    // helper
    // =========================

    address constant OP_TOKEN = 0x4200000000000000000000000000000000000042;

    function _getMessage(bytes32 pool, uint256 amountIn, bool fail) internal view returns (bytes memory) {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        if (pool == optimismUniswapV3_USDC_OP_Pool) {
            m2Data.tokenIn = outputTokenUSDC;
        } else {
            m2Data.tokenIn = outputTokenWETH;
        }
        m2Data.fullAmount = amountIn;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pool));
        m2Data.tokensOut = Solarray.addresses(OP_TOKEN);

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data })[0];
        assembly {
            mstore(0, quoterAmountOut)
        }

        m2Data.minAmountsOut = fail ? Solarray.uint256s(quoterAmountOut * 2) : Solarray.uint256s(quoterAmountOut);

        return abi.encodeCall(
            IEntryPoint.multicall,
            (
                Solarray.bytess(
                    abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                    abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
                )
            )
        );
    }
}
