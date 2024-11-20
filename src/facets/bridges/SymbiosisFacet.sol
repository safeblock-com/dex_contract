// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";

interface ISymbiosis {
    struct MetaSynthesizeTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rtoken;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address syntCaller;
        uint256 chainID;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
        address revertableAddress;
        bytes32 clientID;
    }

    function metaSynthesize(MetaSynthesizeTransaction memory _metaSynthesizeTransaction) external returns (bytes32);

    function multicall(
        uint256 amountIn,
        bytes[] memory callData,
        address[] memory receiveSides,
        address[] memory path,
        uint256[] memory offset,
        address to
    )
        external;

    function swap(
        uint256 tokenIdIn,
        uint256 tokenIdOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address transferFrom,
        uint256 deadline
    )
        external;
}

contract SymbiosisFacet {
    using TransferHelper for address;

    ISymbiosis internal immutable _portal;

    constructor(address portal_) {
        _portal = ISymbiosis(portal_);
    }

    function portal() external view returns (address) {
        return address(_portal);
    }

    struct SymbiosisTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rtoken;
        address chain2address;
        address[] swapTokens;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
    }

    function send(SymbiosisTransaction calldata symbiosisTransaction) external {
        address sender = TransientStorageFacetLibrary.getSenderAddress();
        if (symbiosisTransaction.rtoken.safeGetBalance({ account: address(this) }) < symbiosisTransaction.amount) {
            symbiosisTransaction.rtoken.safeTransferFrom({
                from: sender,
                to: address(this),
                value: symbiosisTransaction.amount
            });
        }

        symbiosisTransaction.rtoken.safeApprove({ spender: address(_portal), value: symbiosisTransaction.amount });

        _portal.metaSynthesize({
            _metaSynthesizeTransaction: ISymbiosis.MetaSynthesizeTransaction({
                stableBridgingFee: symbiosisTransaction.stableBridgingFee,
                amount: symbiosisTransaction.amount,
                rtoken: symbiosisTransaction.rtoken,
                chain2address: symbiosisTransaction.chain2address,
                receiveSide: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8, // Synthesis on BOBA BNB
                oppositeBridge: 0x5523985926Aa12BA58DC5Ad00DDca99678D7227E, // BridgeV2 on BOBA BNB
                syntCaller: sender,
                chainID: 56_288, // Boba BNB
                swapTokens: symbiosisTransaction.swapTokens,
                secondDexRouter: 0xcB28fbE3E9C0FEA62E0E63ff3f232CECfE555aD4, // MulticallRouter on BOBA BNB
                secondSwapCalldata: symbiosisTransaction.secondSwapCalldata,
                finalReceiveSide: symbiosisTransaction.finalReceiveSide,
                finalCalldata: symbiosisTransaction.finalCalldata,
                finalOffset: symbiosisTransaction.finalOffset, // calculate final offset for multicall with transfer token or multiswap
                revertableAddress: symbiosisTransaction.chain2address,
                clientID: bytes32("SafeBlock")
            })
        });
    }
}
