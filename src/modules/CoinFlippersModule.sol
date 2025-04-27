// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ICoinFlippersModule } from "./interfaces/ICoinFlippersModule.sol";

import { ICoinFlippersVault } from "./interfaces/ICoinFlippersVault.sol";

import { TransferHelper } from "../facets/libraries/TransferHelper.sol";
import { TransientStorageFacetLibrary } from "../libraries/TransientStorageFacetLibrary.sol";

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
    {
        uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: tokenAddress });

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
