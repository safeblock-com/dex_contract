// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import { E18 } from "../../src/libraries/Constants.sol";

contract AcrossFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("ethereum_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: inputTokenUSDC, to: user, give: 1000e6 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    function test_acrossFacet_constructor_shouldInitializeInConstructor() external {
        AcrossFacet _acrossFacet = new AcrossFacet({
            spokePool_: contracts.acrossSpokePool,
            wrappedNative_: contracts.wrappedNative,
            endpointV2: contracts.layerZeroEndpointV2
        });

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

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositAfterTransferTokenFromUser() external checkStorage {
        _resetPrank(user);

        uint256 inputAmount = 1000e6;

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(inputTokenUSDC),
            amounts: Solarray.uint256s(inputAmount)
        });

        IERC20(inputTokenUSDC).approve({ spender: address(entryPoint), amount: inputAmount });

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool);

        _expectERC20TransferFromCall(inputTokenUSDC, user, address(entryPoint), inputAmount);
        _expectERC20ApproveCall(inputTokenUSDC, contracts.acrossSpokePool, inputAmount);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: inputTokenUSDC,
                            outputToken: outputTokenUSDC,
                            inputAmount: 0,
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

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositWithNativeCurrency() external checkStorage {
        _resetPrank(user);

        uint256 inputAmount = 1000e18;

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool);

        entryPoint.multicall{ value: inputAmount }({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: address(0), // WETH
                            outputToken: outputTokenWETH,
                            inputAmount: 0,
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

    address constant tokenForSwap = 0xF19308F923582A6f7c465e5CE7a9Dc1BEC6665B1;
    bytes32 constant poolForSwap = 0x800000000000000000000000c45A81BC23A64eA556ab4CdF08A86B61cdcEEA8b;

    function test_acrossFacet_sendAcrossDepositV3_shouldSendDepositAfterSwap() external checkStorage {
        deal({ token: tokenForSwap, to: user, give: 1000e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: tokenForSwap, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(poolForSwap, 1e18)));
        mData.tokensOut = Solarray.addresses(inputTokenWETH);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(tokenForSwap),
            amounts: Solarray.uint256s(1000e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(tokenForSwap).approve({ spender: address(entryPoint), amount: 1000e18 });

        uint256 inputAmount = mData.minAmountsOut[0];

        bytes memory message = _getMessage(optimismUniswapV3_WETH_OP_Pool);

        _expectERC20ApproveCall(inputTokenWETH, contracts.acrossSpokePool, inputAmount);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(
                    AcrossFacet.sendAcrossDepositV3,
                    (
                        IAcrossFacet.V3AcrossDepositParams({
                            recipient: address(entryPoint),
                            inputToken: inputTokenWETH, // WETH
                            outputToken: outputTokenWETH,
                            inputAmount: 0,
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

    function _getMessage(bytes32 pool) internal view returns (bytes memory) {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        if (pool == optimismUniswapV3_USDC_OP_Pool) {
            mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: inputTokenUSDC, amount: 1 }));
        } else {
            mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: outputTokenWETH, amount: 1 }));
        }
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pool));
        mData.tokensOut = Solarray.addresses(OP_TOKEN);
        mData.minAmountsOut = Solarray.uint256s(0);

        return abi.encodeWithSignature(
            "multicall(bytes[])",
            Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        );
    }
}
