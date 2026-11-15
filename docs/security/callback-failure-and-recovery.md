# AjoFlow Callback Funding & Failure Recovery Model

Under Reactive Omni, cross-chain callbacks incur destination-chain execution fees. An underfunded callback contract accrues debt, halting callback delivery. This document defines the economic model, monitoring mechanisms, and failure recovery procedures.

---

## 1. Economic & Fee Responsibilities

### Two-Sided Funding Architecture

```text
[ Reactive Lasna ]                              [ Base Sepolia ]
AjoSettlementReactive                           AjoSettlementReceiver
   └── Pays System Contract (REACT)                └── Pays Callback Proxy (ETH)
```

1. **Reactive Lasna Side:**
   - Contract: `AjoSettlementReactive`
   - Currency: Native REACT tokens.
   - Mechanism: Charged by the Lasna `SYSTEM` contract for `react()` execution and subscription management.
   - Funding Method: Direct transfer of REACT to `AjoSettlementReactive`.

2. **Base Sepolia Destination Side:**
   - Contract: `AjoSettlementReceiver`
   - Currency: Native Base Sepolia ETH.
   - Mechanism: Charged by the Callback Proxy (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`) for delivering cross-chain callbacks.
   - Funding Method: Direct transfer of ETH to `AjoSettlementReceiver`.

---

## 2. Debt Rules & Automatic Clearance

> [!WARNING]
> **Source Library Discovery:** In the official Reactive Omni library (`lib/reactive-lib-omni/src/base/AbstractPayer.sol`), `receive() virtual external payable {}` has an empty body. Merely receiving funds raises `address(this).balance` but does **not** automatically pay outstanding debt to `_SERVICE_PROVIDER`.

### The AjoFlow Debt Settlement Enhancement
To ensure that funds sent to the contract immediately resolve outstanding debt, both `AjoSettlementReceiver` and `AjoSettlementReactive` implement:

1. **Automatic Debt Clearance on Receive:**
   ```solidity
   receive() external payable override {
       _coverDebt();
   }
   ```
2. **Explicit Public Debt Clearance:**
   ```solidity
   function coverDebt() external {
       _coverDebt();
   }
   ```
This guarantees that whenever anyone sends native ETH or REACT to the contracts, `_SERVICE_PROVIDER.debt(address(this))` is checked and paid immediately via low-level value transfer to the service provider. Furthermore, anyone can invoke `coverDebt()` at any time to clear accrued debt from existing contract balances.

---

## 3. Duplicate Callback Handling & Gas Conservation

### The Problem with Reverting on Duplicate Settlement
Previously, attempting to settle an already-settled round reverted with `RoundAlreadySettled()`. If a duplicate or retried callback was delivered by the Callback Proxy:
- The transaction reverted on Base Sepolia.
- Full gas was consumed up to the revert point.
- The Callback Proxy recorded a failed execution and still charged `AjoSettlementReceiver` for gas, unnecessarily depleting reserves.

### The Corrected Idempotency Pattern
In the updated implementation:
```solidity
Round storage round = _rounds[circleId][roundIndex];
// Safe idempotent return: If round has already been settled, return false without re-transferring funds
if (round.isSettled) {
    return false;
}
```
And in `AjoSettlementReceiver.executeSettlement`:
```solidity
bool settled = circleManager.settleRound(circleId, roundIndex);
if (settled) {
    emit SettlementTriggered(circleId, roundIndex, reactiveSender);
}
```
**Benefits:**
1. **Zero Double-Payout Risk:** Funds cannot be transferred again because `round.isSettled` is already `true`.
2. **Gas Efficiency:** The duplicate callback exits cleanly in ~30,000 gas rather than reverting, preventing unnecessary proxy penalties.
3. **Authorization Preserved:** `onlyServiceProvider` and `onlyCallbackSender` are still strictly enforced prior to executing the call.

---

## 4. Failure Modes & Recovery Matrix

| Failure Mode | Immediate Behavior | Recovery Procedure |
| :--- | :--- | :--- |
| **Exhausted Receiver ETH** | Callback Proxy records debt; subsequent callbacks halt | Anyone sends ETH to `AjoSettlementReceiver`. The overridden `receive()` immediately triggers `_coverDebt()`. |
| **Callback Gas Exhaustion** | Transaction runs out of gas during callback execution | Round remains in `isFunded == true`, `isSettled == false`. Relayer or permissionless retry triggers settlement with sufficient gas. |
| **Exhausted Reactive REACT** | Lasna halts subscription triggers | Deployer or community sends REACT to `AjoSettlementReactive`. The overridden `receive()` triggers `_coverDebt()`. |
| **Temporary Network Outage** | Payout delayed until cross-chain relay catches up | Events are immutable on Base Sepolia. Once network resumes, the Reactive relayer processes the log. |
