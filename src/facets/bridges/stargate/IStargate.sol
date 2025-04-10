// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Solidity does not support splitting import across multiple lines
import { IOFT, SendParam, MessagingFee, MessagingReceipt, OFTReceipt } from "./IOFT.sol";

/// @notice Stargate implementation type.
enum StargateType {
    Pool,
    OFT
}

/// @notice Ticket data for bus ride.
struct Ticket {
    uint72 ticketId;
    bytes passengerBytes;
}

/// @title Interface for Stargate.
/// @notice Defines an API for sending tokens to destination chains.
interface IStargate is IOFT {
    /// @dev This function is same as `send` in OFT interface but returns the ticket data if in the bus ride mode,
    /// which allows the caller to ride and drive the bus in the same transaction.
    function sendToken(
        SendParam calldata sendParam,
        MessagingFee calldata fee,
        address refundAddress
    )
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket);

    /// @notice Returns the Stargate implementation type.
    function stargateType() external pure returns (StargateType);
}
