// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IPayable } from "../../lib/reactive-lib-omni/src/interfaces/IPayable.sol";
import { AbstractPayer } from "../../lib/reactive-lib-omni/src/base/AbstractPayer.sol";
import { AbstractCallback } from "../../lib/reactive-lib-omni/src/base/AbstractCallback.sol";
import { IAjoSettlementReceiver } from "./interfaces/IAjoSettlementReceiver.sol";
import { IAjoCircleManager } from "./interfaces/IAjoCircleManager.sol";

/**
 * @title AjoSettlementReceiver
 * @notice Receives verified callbacks from the Reactive Network Callback Proxy and settles rounds in AjoCircleManager.
 */
contract AjoSettlementReceiver is AbstractCallback, IAjoSettlementReceiver {
    IAjoCircleManager public immutable circleManager;

    event SettlementTriggered(uint256 indexed circleId, uint256 indexed roundIndex, address indexed reactiveSender);

    constructor(
        IPayable callbackProxy_,
        address callbackSender_,
        IAjoCircleManager circleManager_
    ) payable AbstractCallback(callbackProxy_, callbackSender_) {
        circleManager = circleManager_;
    }

    /**
     * @notice Callback entry point invoked by the Reactive Callback Proxy.
     * @param reactiveSender Injected by Callback Proxy from the payload's first parameter.
     * @param circleId Circle ID to settle.
     * @param roundIndex Round index to settle.
     */
    function executeSettlement(
        address reactiveSender,
        uint256 circleId,
        uint256 roundIndex
    ) external override onlyServiceProvider onlyCallbackSender(reactiveSender) {
        bool settled = circleManager.settleRound(circleId, roundIndex);
        if (settled) {
            emit SettlementTriggered(circleId, roundIndex, reactiveSender);
        }
    }

    /**
     * @notice Allows anyone to trigger debt clearance to the callback proxy.
     */
    function coverDebt() external {
        _coverDebt();
    }

    /**
     * @notice Receives funds and automatically settles any outstanding debt with the callback proxy.
     */
    receive() external payable override(AbstractPayer) {
        _coverDebt();
    }
}
