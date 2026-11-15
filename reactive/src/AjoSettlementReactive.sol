// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ISystemContract } from "../../lib/reactive-lib-omni/src/interfaces/ISystemContract.sol";
import { IReactive } from "../../lib/reactive-lib-omni/src/interfaces/IReactive.sol";
import { AbstractReactive } from "../../lib/reactive-lib-omni/src/base/AbstractReactive.sol";
import { IAjoSettlementReceiver } from "../../contracts/src/interfaces/IAjoSettlementReceiver.sol";

/**
 * @title AjoSettlementReactive
 * @notice Subscribes to RoundFunded events on Base Sepolia and autonomously requests callback settlements on Base Sepolia.
 */
contract AjoSettlementReactive is AbstractReactive {
    // keccak256("RoundFunded(uint256,uint256,address,uint256)")
    uint256 public constant ROUND_FUNDED_TOPIC0 = 0x52f68a3a7909db0977c03511ae375412cccb31b41a9cfcb8d6d2678e7d96255a;

    uint256 public immutable originChainId;
    uint256 public immutable destinationChainId;
    address public immutable circleManager;
    address public immutable settlementReceiver;
    uint64 public immutable callbackGasLimit;

    // Deduplication tracking: circleId => roundIndex => processed
    mapping(uint256 => mapping(uint256 => bool)) public processedRounds;

    event CallbackRequested(
        uint256 indexed circleId,
        uint256 indexed roundIndex,
        address indexed recipient,
        uint256 totalAmount
    );

    error InvalidOriginChain();
    error InvalidSourceContract();
    error InvalidTopic();
    error RoundAlreadyProcessed();

    constructor(
        uint256 originChainId_,
        uint256 destinationChainId_,
        address circleManager_,
        address settlementReceiver_,
        uint64 callbackGasLimit_
    ) payable {
        originChainId = originChainId_;
        destinationChainId = destinationChainId_;
        circleManager = circleManager_;
        settlementReceiver = settlementReceiver_;
        callbackGasLimit = callbackGasLimit_;

        // Subscribe to RoundFunded event from circleManager on originChain
        SYSTEM.subscribe(
            originChainId_,
            circleManager_,
            ROUND_FUNDED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    /**
     * @notice Reactive Network entry point invoked by SYSTEM contract upon matching event log.
     * @param log_ Encapsulated log record from monitored origin chain.
     */
    function react(LogRecord calldata log_) external override onlySystem {
        if (log_.chainId != originChainId) revert InvalidOriginChain();
        if (log_.contractAddress != circleManager) revert InvalidSourceContract();
        if (log_.topic0 != ROUND_FUNDED_TOPIC0) revert InvalidTopic();

        uint256 circleId = log_.topic1;
        uint256 roundIndex = log_.topic2;
        address recipient = address(uint160(log_.topic3));
        uint256 totalAmount = abi.decode(log_.data, (uint256));

        if (processedRounds[circleId][roundIndex]) {
            return; // Deduplication safe return
        }
        processedRounds[circleId][roundIndex] = true;

        bytes memory payload = abi.encodeWithSelector(
            IAjoSettlementReceiver.executeSettlement.selector,
            address(0), // Placeholder for Reactive Callback Proxy address injection
            circleId,
            roundIndex
        );

        SYSTEM.requestCallbackV_1_0(
            ISystemContract.CallbackConfiguration_V_1_0({
                chainId: destinationChainId,
                recipient: settlementReceiver,
                gasLimit: callbackGasLimit,
                payload: payload
            })
        );

        emit CallbackRequested(circleId, roundIndex, recipient, totalAmount);
    }
}
