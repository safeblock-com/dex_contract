// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.t.sol";
import "./Helpers.t.sol";

contract PayFeeTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();
    }

    // =========================
    // multicall with fee
    // =========================

    function test_entryPoint_multicall_shouldPayFeeAfterTransferFrom() external {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        EntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, address(0)),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, 1000e18 - 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(WBNB, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(USDT, user, 1000e18 - 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(USDT, address(feeContract), 1000e18 * 300 / 1_000_000);
        entryPoint.multicall{ value: 1000e18 }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT, WBNB))))
        });
    }

    function test_entryPoint_multicall_shouldPayFeePermit2() external {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: WBNB, to: user, give: 1000e18 });

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT, WBNB),
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

        _resetPrank(user);
        IERC20(USDT).approve({ spender: contracts.permit2, amount: 1000e18 });
        IERC20(WBNB).approve({ spender: contracts.permit2, amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, 1000e18 - 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(WBNB, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(USDT, user, 1000e18 - 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(USDT, address(feeContract), 1000e18 * 300 / 1_000_000);
        entryPoint.multicall({
            tokenTransfersPermit2: tokenTransfersPermit2,
            data: Solarray.bytess(abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(USDT, WBNB))))
        });
    }

    function test_entryPoint_multicall_shouldPayMetaMulticall() external {
        _resetPrank(owner);
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
        quoter.setRouter({ router: address(entryPoint) });

        deal({ token: USDT, to: user, give: 1000e18 });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.2e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });
        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        uint256 nonce = ITransferFacet(address(entryPoint)).getNonceForPermit2({ user: user });
        uint256 deadline = block.timestamp + 1200;

        IEntryPoint.TokenTransfersPermit2 memory tokenTransfersPermit2 = IEntryPoint.TokenTransfersPermit2({
            tokens: Solarray.addresses(USDT),
            amounts: Solarray.uint256s(1000e18),
            nonce: nonce,
            deadline: deadline,
            signature: new bytes(0),
            feeToken: WBNB,
            feeAmount: mData.minAmountsOut[0] * 0.1e18 / 1e18
        });

        bytes[] memory data = Solarray.bytess(
            abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
            abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
        );

        tokenTransfersPermit2.signature = _permit2Sign(
            userPk,
            tokenTransfersPermit2.tokens,
            tokenTransfersPermit2.amounts,
            nonce,
            deadline,
            this.hash({ data: data, sender: owner })
        );

        _resetPrank(user);
        IERC20(USDT).approve({ spender: contracts.permit2, amount: 1000e18 });

        _resetPrank(owner, owner);

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(USDT, address(feeContract), 1000e18 * 300 / 1_000_000);
        _expectERC20TransferCall(WBNB, owner, mData.minAmountsOut[0] * 0.1e18 / 1e18);
        entryPoint.metaMulticall({ sender: user, tokenTransfersPermit2: tokenTransfersPermit2, data: data });
    }
}
