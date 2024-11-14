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

    function send(
        uint256 stableBridgingFee,
        uint256 amount,
        address rtoken,
        address chain2address,
        address receiveSide,
        address oppositeBridge,
        address syntCaller,
        address finalReceiveSide,
        bytes calldata finalCalldata,
        uint256 finalOffset
    )
        external
    {
        
    }
}
