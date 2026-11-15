// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IAjoCircleManager } from "./interfaces/IAjoCircleManager.sol";

/**
 * @title AjoCircleManager
 * @notice Core state machine and USDC vault accounting for AjoFlow circles on Base Sepolia.
 */
contract AjoCircleManager is IAjoCircleManager, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_MEMBERS_MVP = 3;
    uint256 public constant TOTAL_ROUNDS_MVP = 3;

    IERC20 public immutable usdc;
    address public settlementReceiver;
    address public owner;

    uint256 public nextCircleId;
    mapping(uint256 => Circle) internal _circles;
    mapping(uint256 => mapping(uint256 => Round)) internal _rounds;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) internal _contributions;

    error UnauthorizedCaller();
    error CircleDoesNotExist();
    error CircleNotAcceptingMembers();
    error CircleNotActive();
    error CircleFull();
    error AlreadyMember();
    error NotMember();
    error InvalidRound();
    error AlreadyContributed();
    error RoundNotFunded();
    error RoundAlreadySettled();
    error InvalidAmount();
    error ZeroAddress();

    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedCaller();
        _;
    }

    modifier onlySettlementReceiver() {
        if (msg.sender != settlementReceiver) revert UnauthorizedCaller();
        _;
    }

    constructor(IERC20 usdc_) {
        if (address(usdc_) == address(0)) revert ZeroAddress();
        usdc = usdc_;
        owner = msg.sender;
        nextCircleId = 1;
    }

    function setSettlementReceiver(address settlementReceiver_) external onlyOwner {
        if (settlementReceiver_ == address(0)) revert ZeroAddress();
        settlementReceiver = settlementReceiver_;
    }

    function createCircle(uint256 contributionAmount) external override nonReentrant returns (uint256 circleId) {
        if (contributionAmount == 0) revert InvalidAmount();

        circleId = nextCircleId++;
        Circle storage circle = _circles[circleId];
        circle.circleId = circleId;
        circle.creator = msg.sender;
        circle.contributionAmount = contributionAmount;
        circle.maxMembers = MAX_MEMBERS_MVP;
        circle.totalRounds = TOTAL_ROUNDS_MVP;
        circle.state = CircleState.AcceptingMembers;
        circle.currentRound = 0;
        circle.members.push(msg.sender);

        emit CircleCreated(circleId, msg.sender, contributionAmount, MAX_MEMBERS_MVP, TOTAL_ROUNDS_MVP);
        emit MemberJoined(circleId, msg.sender, 0);
    }

    function joinCircle(uint256 circleId) external override nonReentrant {
        Circle storage circle = _circles[circleId];
        if (circle.circleId == 0) revert CircleDoesNotExist();
        if (circle.state != CircleState.AcceptingMembers) revert CircleNotAcceptingMembers();
        if (circle.members.length >= circle.maxMembers) revert CircleFull();

        for (uint256 i = 0; i < circle.members.length; i++) {
            if (circle.members[i] == msg.sender) revert AlreadyMember();
        }

        uint256 memberIndex = circle.members.length;
        circle.members.push(msg.sender);
        emit MemberJoined(circleId, msg.sender, memberIndex);

        if (circle.members.length == circle.maxMembers) {
            circle.state = CircleState.Active;
            circle.currentRound = 1;
            // Initialize rounds
            for (uint256 r = 1; r <= circle.totalRounds; r++) {
                _rounds[circleId][r] = Round({
                    roundIndex: r,
                    recipient: circle.members[r - 1],
                    contributionTotal: 0,
                    contributionsCount: 0,
                    isFunded: false,
                    isSettled: false
                });
            }
        }
    }

    function contribute(uint256 circleId, uint256 roundIndex) external override nonReentrant {
        Circle storage circle = _circles[circleId];
        if (circle.circleId == 0) revert CircleDoesNotExist();
        if (circle.state != CircleState.Active) revert CircleNotActive();
        if (roundIndex != circle.currentRound) revert InvalidRound();

        Round storage round = _rounds[circleId][roundIndex];
        if (round.isFunded) revert InvalidRound();
        if (_contributions[circleId][roundIndex][msg.sender]) revert AlreadyContributed();

        bool isMember = false;
        for (uint256 i = 0; i < circle.members.length; i++) {
            if (circle.members[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        if (!isMember) revert NotMember();

        _contributions[circleId][roundIndex][msg.sender] = true;
        round.contributionsCount++;
        round.contributionTotal += circle.contributionAmount;

        usdc.safeTransferFrom(msg.sender, address(this), circle.contributionAmount);

        emit ContributionReceived(circleId, msg.sender, roundIndex, circle.contributionAmount);

        if (round.contributionsCount == circle.maxMembers) {
            round.isFunded = true;
            emit RoundFunded(circleId, roundIndex, round.recipient, round.contributionTotal);
        }
    }

    function settleRound(
        uint256 circleId,
        uint256 roundIndex
    ) external override onlySettlementReceiver nonReentrant returns (bool) {
        Circle storage circle = _circles[circleId];
        if (circle.circleId == 0) revert CircleDoesNotExist();
        if (circle.state != CircleState.Active && circle.state != CircleState.Completed) revert CircleNotActive();

        Round storage round = _rounds[circleId][roundIndex];
        // Safe idempotent return: If round has already been settled, return false without re-transferring funds
        if (round.isSettled) {
            return false;
        }

        if (roundIndex != circle.currentRound) revert InvalidRound();
        if (!round.isFunded) revert RoundNotFunded();

        round.isSettled = true;
        uint256 payoutAmount = round.contributionTotal;
        address recipient = round.recipient;

        if (circle.currentRound == circle.totalRounds) {
            circle.state = CircleState.Completed;
        } else {
            circle.currentRound++;
        }

        usdc.safeTransfer(recipient, payoutAmount);

        emit RoundSettled(circleId, roundIndex, recipient, payoutAmount);
        return true;
    }

    function getCircle(uint256 circleId) external view override returns (Circle memory) {
        return _circles[circleId];
    }

    function getRound(uint256 circleId, uint256 roundIndex) external view override returns (Round memory) {
        return _rounds[circleId][roundIndex];
    }

    function hasContributed(
        uint256 circleId,
        uint256 roundIndex,
        address member
    ) external view override returns (bool) {
        return _contributions[circleId][roundIndex][member];
    }
}
