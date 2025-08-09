// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "../libraries/TransferHelper.sol";
import { Utils } from "../libraries/Utils.sol";

import { ICoinFlippersVault } from "./interfaces/ICoinFlippersVault.sol";

import { ICoinFlippersModule } from "./interfaces/ICoinFlippersModule.sol";

/// @title CoinFlippersModule
contract CoinFlippersModule is ICoinFlippersModule {
    using TransferHelper for address;

    address internal immutable _coinFlippersVault;

    // =======================
    // constructor
    // =======================

    /// @notice Sets immutable storage
    constructor(address coinFlippersVault_) {
        _coinFlippersVault = coinFlippersVault_;
    }

    // =======================
    // getter
    // =======================

    /// @notice Returns coinFlippersVault address
    function coinFlippersVault() external view returns (address) {
        return _coinFlippersVault;
    }

    // =======================
    // main function
    // =======================

    /// @inheritdoc ICoinFlippersModule
    function deposit(
        bytes32 merchantId,
        bytes32 paymentId,
        address tokenAddress,
        uint256 deadline,
        bytes calldata signature
    )
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();
        uint256 amount = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: tokenAddress });

        if (amount > 0) {
            tokenAddress.safeApprove({ spender: _coinFlippersVault, value: amount });

            ICoinFlippersVault(_coinFlippersVault).depositFlexibleAmount({
                merchantId: merchantId,
                paymentId: paymentId,
                tokenAddress: tokenAddress,
                amount: amount,
                deadline: deadline,
                signature: signature
            });
        }
    }
}
