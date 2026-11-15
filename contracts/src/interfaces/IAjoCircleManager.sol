// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IAjoEvents } from "./IAjoEvents.sol";

/**
 * @title IAjoCircleManager
 * @notice Interface for Base Sepolia AjoFlow circle state and USDC accounting.
 */
interface IAjoCircleManager is IAjoEvents {
    enum CircleState {
        AcceptingMembers,
        Active,
        Completed,
        Cancelled
    }

    struct Round {
        uint256 roundIndex;
        address recipient;
        uint256 contributionTotal;
        uint256 contributionsCount;
        bool isFunded;
        bool isSettled;
    }

    struct Circle {
        uint256 circleId;
        address creator;
        uint256 contributionAmount;
        uint256 maxMembers;
        uint256 currentRound;
        uint256 totalRounds;
        CircleState state;
        address[] members;
    }

    function createCircle(uint256 contributionAmount) external returns (uint256 circleId);

    function joinCircle(uint256 circleId) external;

    function contribute(uint256 circleId, uint256 roundIndex) external;

    function settleRound(uint256 circleId, uint256 roundIndex) external;

    function getCircle(uint256 circleId) external view returns (Circle memory);

    function getRound(uint256 circleId, uint256 roundIndex) external view returns (Round memory);

    function hasContributed(uint256 circleId, uint256 roundIndex, address member) external view returns (bool);
}
