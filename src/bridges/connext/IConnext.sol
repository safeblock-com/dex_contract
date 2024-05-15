// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
    TransferInfo params;
    address[] routers;
    bytes[] routerSignatures;
    address sequencer;
    bytes sequencerSignature;
}

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called)
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called)\
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
    uint32 originDomain;
    uint32 destinationDomain;
    uint32 canonicalDomain;
    address to;
    address delegate;
    bool receiveLocal;
    bytes callData;
    uint256 slippage;
    address originSender;
    uint256 bridgedAmt;
    uint256 normalizedIn;
    uint256 nonce;
    bytes32 canonicalId;
}

/**
 * @notice Enum representing status of destination transfer
 * @dev Status is only assigned on the destination domain, will always be "none" for the
 * origin domains
 * @return uint - Index of value in enum
 */
enum DestinationTransferStatus {
    None, // 0
    Reconciled, // 1
    Executed, // 2
    Completed // 3 - executed + reconciled

}

// Tokens are identified by a TokenId:
// domain - 4 byte chain ID of the chain from which the token originates
// id - 32 byte identifier of the token address on the origin chain, in that chain's address format
struct TokenId {
    uint32 domain;
    bytes32 id;
}

interface IConnext {
    // ============ BRIDGE ==============

    function xcall(
        uint32 destination,
        address to,
        address asset,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes calldata callData
    )
        external
        payable
        returns (bytes32);

    function xcallIntoLocal(
        uint32 destination,
        address to,
        address asset,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes calldata callData
    )
        external
        payable
        returns (bytes32);

    function execute(ExecuteArgs calldata args) external returns (bytes32 transferId);

    function forceUpdateSlippage(TransferInfo calldata params, uint256 slippage) external;

    function forceReceiveLocal(TransferInfo calldata params) external;

    function bumpTransfer(bytes32 transferId) external payable;

    function routedTransfers(bytes32 transferId) external view returns (address[] memory);

    function transferStatus(bytes32 transferId) external view returns (DestinationTransferStatus);

    function remote(uint32 domain) external view returns (address);

    function domain() external view returns (uint256);

    function nonce() external view returns (uint256);

    function approvedSequencers(address sequencer) external view returns (bool);

    function xAppConnectionManager() external view returns (address);

    // ============ ROUTERS ==============

    function LIQUIDITY_FEE_NUMERATOR() external view returns (uint256);

    function LIQUIDITY_FEE_DENOMINATOR() external view returns (uint256);

    function getRouterApproval(address router) external view returns (bool);

    function getRouterRecipient(address router) external view returns (address);

    function getRouterOwner(address router) external view returns (address);

    function getProposedRouterOwner(address router) external view returns (address);

    function getProposedRouterOwnerTimestamp(address router) external view returns (uint256);

    function maxRoutersPerTransfer() external view returns (uint256);

    function routerBalances(address router, address asset) external view returns (uint256);

    function getRouterApprovalForPortal(address router) external view returns (bool);

    function initializeRouter(address owner, address recipient) external;

    function setRouterRecipient(address router, address recipient) external;

    function proposeRouterOwner(address router, address proposed) external;

    function acceptProposedRouterOwner(address router) external;

    function addRouterLiquidityFor(uint256 amount, address local, address router) external payable;

    function addRouterLiquidity(uint256 amount, address local) external payable;

    function removeRouterLiquidityFor(
        TokenId memory canonical,
        uint256 amount,
        address payable to,
        address router
    )
        external;

    function removeRouterLiquidity(TokenId memory canonical, uint256 amount, address payable to) external;
}
