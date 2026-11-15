// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IAjoEvents
 * @notice Standard event schemas for the AjoFlow autonomous ROSCA protocol.
 */
interface IAjoEvents {
    /// @notice Emitted when a new circle is initialized.
    event CircleCreated(
        uint256 indexed circleId,
        address indexed creator,
        uint256 contributionAmount,
        uint256 maxMembers,
        uint256 totalRounds
    );

    /// @notice Emitted when a new member joins an existing circle.
    event MemberJoined(uint256 indexed circleId, address indexed member, uint256 memberIndex);

    /// @notice Emitted when a member submits their round contribution.
    event ContributionReceived(uint256 indexed circleId, address indexed member, uint256 roundIndex, uint256 amount);

    /// @notice Emitted exactly once when a round reaches full contribution quorum.
    /// @dev Monitored by AjoSettlementReactive on Reactive Lasna.
    event RoundFunded(
        uint256 indexed circleId,
        uint256 indexed roundIndex,
        address indexed recipient,
        uint256 totalAmount
    );

    /// @notice Emitted when a round payout has been settled to the recipient.
    event RoundSettled(
        uint256 indexed circleId,
        uint256 indexed roundIndex,
        address indexed recipient,
        uint256 totalAmount
    );

    /// @notice Emitted when a Reactive callback initiates settlement.
    event SettlementRequested(
        uint256 indexed circleId,
        uint256 indexed roundIndex,
        address indexed recipient,
        uint256 totalAmount
    );
}
