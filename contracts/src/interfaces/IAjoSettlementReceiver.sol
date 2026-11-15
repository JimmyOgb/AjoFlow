// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IAjoSettlementReceiver
 * @notice Interface for Base Sepolia callback receiver invoked by Reactive Callback Proxy.
 */
interface IAjoSettlementReceiver {
    function executeSettlement(address reactiveSender, uint256 circleId, uint256 roundIndex) external;
}
