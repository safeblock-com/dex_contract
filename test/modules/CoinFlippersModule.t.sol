// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {
    BaseTest,
    CoinFlippersModule,
    ICoinFlippersModule,
    ICoinFlippersVault,
    IMultiswapRouterFacet,
    Solarray,
    TransferHelper
} from "../BaseTest.t.sol";

contract CoinFlippersModuleTest is BaseTest {
    using TransferHelper for address;

    function setUp() external {
        vm.createSelectFork("ethereum_public");

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: usdtMainnet, to: user, give: 1000e6 });
    }

    // =========================
    // constructor
    // =========================

    function test_coinFlippersModule_constructor_shouldSetImmutableStorage() external {
        CoinFlippersModule _coinFlippersModule = new CoinFlippersModule({ coinFlippersVault_: coinFlippersVault });
        assertEq(_coinFlippersModule.coinFlippersVault(), coinFlippersVault);
    }

    // =========================
    // deposit
    // =========================

    bytes32 pair = 0x000000000000000000000bb8b56034aaEeDebEd89af24e6675fCbCEF30f21DBf;
    address coinFlippersToken = 0x5b5F4a883626E75f29060C4ffde0057DD3a57f62;
    address usdtMainnet = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function test_coinFlippersModule_deposit_shouldDepositTokensIntoCoinFlippersVault() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = usdtMainnet;
        m2Data.fullAmount = 1000e6;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(coinFlippersToken);
        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        vm.mockCall(
            coinFlippersVault,
            abi.encodeCall(
                ICoinFlippersVault.depositFlexibleAmount,
                (
                    keccak256("merchantID"),
                    keccak256("paymentID"),
                    coinFlippersToken,
                    m2Data.minAmountsOut[0],
                    block.timestamp + 100,
                    new bytes(61)
                )
            ),
            new bytes(0)
        );

        _resetPrank(user);

        usdtMainnet.safeApprove({ spender: address(entryPoint), value: 1000e6 });

        _expectERC20ApproveCall(coinFlippersToken, coinFlippersVault, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(
                    ICoinFlippersModule.deposit,
                    (
                        keccak256("merchantID"),
                        keccak256("paymentID"),
                        coinFlippersToken,
                        block.timestamp + 100,
                        new bytes(61)
                    )
                )
            )
        });
    }
}
