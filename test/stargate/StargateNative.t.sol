// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    ITransferFacet,
    StargateFacet,
    IStargateFacet,
    TransferHelper
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract StargateFacetTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("ethereum_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ to: user, give: 1000e18 });

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
    }

    // =========================
    // sendStargate with native
    // =========================

    address stargatePool = 0x77b2043768d28E9C9aB44E1aBfC95944bcE57931;
    uint16 dstEidV2 = 30_110;

    function test_stargateFacet_sendStargateNative_shouldRevertIfSendStargateWithNativePool()
        external
        checkTokenStorage(new address[](0))
    {
        _resetPrank(user);

        (uint256 fee,) = IStargateFacet(address(entryPoint)).quoteV2({
            poolAddress: stargatePool,
            dstEid: dstEidV2,
            amountLD: 0.111111111111111111e18,
            composer: user,
            composeMsg: bytes(""),
            composeGasLimit: 0
        });

        assertGt(fee, 0.111111111111111111e18);

        vm.expectRevert(IStargateFacet.StargateFacet_UnsupportedAsset.selector);
        entryPoint.multicall{ value: fee }({
            data: Solarray.bytess(
                abi.encodeCall(
                    IStargateFacet.sendStargateV2, (stargatePool, dstEidV2, 0.111111111111111111e18, user, 0, bytes(""))
                )
            )
        });

        assertEq(address(entryPoint).balance, 0);
    }
}
