// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICircleBridge {
    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param amount amount of tokens to burn
     * @param dstChainId destination chainId (ETH = 0, AVAX = 1)
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @return nonce unique nonce reserved by message
     */
    function depositForBurn(
        uint256 amount,
        uint64 dstChainId,
        bytes32 mintRecipient,
        address burnToken
    )
        external
        returns (uint64 nonce);

    function totalFee(
        uint256 amount,
        uint64 dstChainId
    )
        external
        view
        returns (uint256 fee, uint256 txFee, uint256 percFee);
}
