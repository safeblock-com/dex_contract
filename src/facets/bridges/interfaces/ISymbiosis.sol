// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
