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

contract AcrossFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("ethereum_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: inputTokenUSDC, to: user, give: 1000e6 });
        deal({ to: user, give: 1000e18 });

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
        quoter.setRouter({ router: address(entryPoint) });
    }

    // =========================
    // constructor
    // =========================

    function test_acrossFacet_constructor_shouldInitializeInConstructor() external {
        AcrossFacet _acrossFacet =
            new AcrossFacet({ spokePool_: contracts.acrossSpokePool, wrappedNative_: contracts.wrappedNative });

        assertEq(_acrossFacet.spokePool(), contracts.acrossSpokePool);
    }

    // =========================
    // sendAcrossDepositV3
    // =========================

    bytes32 constant optimismUniswapV3_USDC_OP_Pool = 0x800000000000000000000000B533c12fB4e7b53b5524EAb9b47d93fF6C7A456F;
    bytes32 constant optimismUniswapV3_WETH_OP_Pool = 0x80000000000000000000000068F5C0A2DE713a54991E01858Fd27a3832401849;

    uint32 constant dstChainId = 10; // optimism
    address constant inputTokenWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant outputTokenWETH = 0x4200000000000000000000000000000000000006;
    address constant inputTokenUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant outputTokenUSDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    uint256 constant outputAmountPercentage = 0.999e18;

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositAfterTransferTokenFromUser()
        external
        checkTokenStorage(Solarray.addresses(inputTokenUSDC))
    {
        _resetPrank(user);

        uint256 inputAmount = 1000e6;
        uint256 outputAmount = inputAmount * outputAmountPercentage / E18;

        IERC20(inputTokenUSDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, outputAmount);

        _expectERC20TransferFromCall(inputTokenUSDC, user, address(entryPoint), inputAmount);
        _expectERC20ApproveCall(inputTokenUSDC, contracts.acrossSpokePool, inputAmount);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: inputTokenUSDC,
                            outputToken: outputTokenUSDC,
                            inputAmount: inputAmount,
                            outputAmountPercent: outputAmountPercentage,
                            destinationChainId: dstChainId,
                            exclusiveRelayer: address(0),
                            quoteTimestamp: uint32(block.timestamp),
                            fillDeadline: uint32(block.timestamp + 3600),
                            exclusivityDeadline: 0,
                            message: message
                        })
                    )
                )
            )
        });
    }

    function test_acrossFacet_sendAcrossDepositV3_shouldRevertIfTransferFromFails()
        external
        checkTokenStorage(Solarray.addresses(inputTokenUSDC))
    {
        _resetPrank(user);

        uint256 inputAmount = 1000e6;
        uint256 outputAmount = inputAmount * outputAmountPercentage / E18;

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, outputAmount);

        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: inputTokenUSDC,
                            outputToken: outputTokenUSDC,
                            inputAmount: inputAmount,
                            outputAmountPercent: outputAmountPercentage,
                            destinationChainId: dstChainId,
                            exclusiveRelayer: address(0),
                            quoteTimestamp: uint32(block.timestamp),
                            fillDeadline: uint32(block.timestamp + 3600),
                            exclusivityDeadline: 0,
                            message: message
                        })
                    )
                )
            )
        });
    }

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositWithNativeCurrency()
        external
        checkTokenStorage(Solarray.addresses(inputTokenWETH))
    {
        _resetPrank(user);

        uint256 inputAmount = 1000e18;
        uint256 outputAmount = inputAmount * outputAmountPercentage / E18;

        bytes memory message = _getMessage(optimismUniswapV3_WETH_OP_Pool, outputAmount);

        assertEq(user.balance, 1000e18);

        entryPoint.multicall{ value: 1000e18 }({
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: address(0), // WETH
                            outputToken: outputTokenWETH,
                            inputAmount: inputAmount,
                            outputAmountPercent: outputAmountPercentage,
                            destinationChainId: dstChainId,
                            exclusiveRelayer: address(0),
                            quoteTimestamp: uint32(block.timestamp),
                            fillDeadline: uint32(block.timestamp + 3600),
                            exclusivityDeadline: 0,
                            message: message
                        })
                    )
                )
            )
        });

        assertEq(user.balance, 0);
    }

    function test_acrossFacet_sendAcrossDepositV3_shouldRevertIfNativeCurrencyNotEnough()
        external
        checkTokenStorage(Solarray.addresses(inputTokenWETH))
    {
        _resetPrank(user);

        uint256 inputAmount = 1000e18;
        uint256 outputAmount = inputAmount * outputAmountPercentage / E18;

        bytes memory message = _getMessage(optimismUniswapV3_WETH_OP_Pool, outputAmount);

        vm.expectRevert();
        entryPoint.multicall{ value: 999e18 }({
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: address(0), // WETH
                            outputToken: outputTokenWETH,
                            inputAmount: inputAmount,
                            outputAmountPercent: outputAmountPercentage,
                            destinationChainId: dstChainId,
                            exclusiveRelayer: address(0),
                            quoteTimestamp: uint32(block.timestamp),
                            fillDeadline: uint32(block.timestamp + 3600),
                            exclusivityDeadline: 0,
                            message: message
                        })
                    )
                )
            )
        });
    }

    address constant tokenForSwap = 0xF19308F923582A6f7c465e5CE7a9Dc1BEC6665B1;
    bytes32 constant poolForSwap = 0x800000000000000000000000c45A81BC23A64eA556ab4CdF08A86B61cdcEEA8b;

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositAfterSwap()
        external
        checkTokenStorage(Solarray.addresses(inputTokenWETH, tokenForSwap))
    {
        deal({ token: tokenForSwap, to: user, give: 1000e18 });

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = tokenForSwap;
        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(poolForSwap));
        m2Data.tokensOut = Solarray.addresses(inputTokenWETH);
        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        IERC20(tokenForSwap).approve({ spender: address(entryPoint), amount: 1000e18 });

        uint256 inputAmount = m2Data.minAmountsOut[0];
        uint256 outputAmount = inputAmount * outputAmountPercentage / E18;

        bytes memory message = _getMessage(optimismUniswapV3_WETH_OP_Pool, outputAmount);

        _expectERC20ApproveCall(inputTokenWETH, contracts.acrossSpokePool, inputAmount);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: inputTokenWETH, // WETH
                            outputToken: outputTokenWETH,
                            inputAmount: inputAmount,
                            outputAmountPercent: outputAmountPercentage,
                            destinationChainId: dstChainId,
                            exclusiveRelayer: address(0),
                            quoteTimestamp: uint32(block.timestamp),
                            fillDeadline: uint32(block.timestamp + 3600),
                            exclusivityDeadline: 0,
                            message: message
                        })
                    )
                )
            )
        });
    }

    // =========================
    // helper
    // =========================

    address constant OP_TOKEN = 0x4200000000000000000000000000000000000042;

    function _getMessage(bytes32 pool, uint256 amountIn) internal view returns (bytes memory) {
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
        m2Data.minAmountsOut = Solarray.uint256s(0);

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
