// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

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

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, false);

        vm.expectRevert(IAcrossFacet.AcrossFacet_NotSpokePool.selector);
        IAcrossFacet(address(entryPoint)).handleV3AcrossMessage({
            tokenSent: outputTokenUSDC,
            amount: 1000e6,
            relayer: address(0),
            message: abi.encode(user, message)
        });
    }

    function test_acrossFacet_handleV3AcrossMessage_shouldCallMessageFromCall() external checkStorage {
        _resetPrank(contracts.acrossSpokePool);

        assertEq(TransferHelper.safeGetBalance({ token: outputTokenUSDC, account: address(entryPoint) }), 1000e6);

        IAcrossFacet(address(entryPoint)).handleV3AcrossMessage({
            tokenSent: outputTokenUSDC,
            amount: 1000e6,
            relayer: address(0),
            message: abi.encode(user, _getMessage(optimismUniswapV3_USDC_OP_Pool, false))
        });

        assertEq(TransferHelper.safeGetBalance({ token: outputTokenUSDC, account: address(entryPoint) }), 0);
    }

    event CallFailed(bytes errorMessage);

    function test_acrossFacet_handleV3AcrossMessage_shouldEmitCallFailedIfMessageFails() external checkStorage {
        _resetPrank(contracts.acrossSpokePool);

        bytes memory message = _getMessage(optimismUniswapV3_USDC_OP_Pool, true);

        uint256 quoterAmountOut;
        assembly {
            quoterAmountOut := mload(0)
        }

        vm.expectEmit();
        emit CallFailed({
            errorMessage: abi.encodeWithSelector(
                Utils.ValueLowerThanExpected.selector, quoterAmountOut, quoterAmountOut * 2
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

    function _getMessage(bytes32 pool, bool fail) internal view returns (bytes memory) {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        if (pool == optimismUniswapV3_USDC_OP_Pool) {
            mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: outputTokenUSDC, amount: 1 }));
        } else {
            mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: outputTokenWETH, amount: 1 }));
        }
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pool));
        mData.tokensOut = Solarray.addresses(OP_TOKEN);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(pool == optimismUniswapV3_USDC_OP_Pool ? outputTokenUSDC : outputTokenWETH),
            amounts: Solarray.uint256s(pool == optimismUniswapV3_USDC_OP_Pool ? 1000e6 : 1000e18)
        });

        uint256 quoterAmountOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData })[0];
        assembly {
            mstore(0, quoterAmountOut)
        }

        mData.minAmountsOut = fail ? Solarray.uint256s(quoterAmountOut * 2) : Solarray.uint256s(quoterAmountOut);

        return abi.encodeWithSignature(
            "multicall(bytes[])",
            Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        );
    }
}
