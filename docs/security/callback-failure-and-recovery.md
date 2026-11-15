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
   - Funding Method: Direct transfer of REACT to `AjoSettlementReactive` (via `receive() external payable`).

2. **Base Sepolia Destination Side:**
   - Contract: `AjoSettlementReceiver`
   - Currency: Native Base Sepolia ETH.
   - Mechanism: Charged by the Callback Proxy (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`) for delivering cross-chain callbacks.
   - Funding Method: Direct transfer of ETH to `AjoSettlementReceiver` (via `receive() external payable`).

---

## 2. Debt Rules & Proactive Monitoring

> [!WARNING]
> **Any Debt Blocks Execution:** Under Reactive Omni's `AbstractPayer` logic, if `_SERVICE_PROVIDER.debt(address(this)) > 0`, the callback proxy drops callbacks until all outstanding debt is paid.

### Monitoring Invariants
- Both contracts expose `_SERVICE_PROVIDER.debt(address(this))` through standard JSON-RPC view calls.
- The AjoFlow deployment scripts and frontend verify that:
  - `AjoSettlementReactive.balance >= 0.05 REACT`
  - `AjoSettlementReceiver.balance >= 0.01 Base Sepolia ETH`
  - Outstanding debt == 0.

### Who Can Add Funds?
- **Permissionless Funding:** Both `AjoSettlementReactive` and `AjoSettlementReceiver` inherit `receive() external payable`. Anyone (deployer, circle members, or automated sponsor bot) can top up gas reserves at any time without special permissions.

---

## 3. Failure Modes & Recovery Matrix

| Failure Mode | Impact | Immediate Behavior | Recovery Procedure |
| :--- | :--- | :--- | :--- |
| **Exhausted Receiver ETH** | Callback cannot be executed by Callback Proxy | Proxy records debt; callback reverts or pauses | Anyone sends ETH to `AjoSettlementReceiver`. Contract invokes `_coverDebt()`. |
| **Callback Gas Exhaustion** | Transaction runs out of gas during callback execution | Callback Proxy records failure; round remains in `isFunded == true`, `isSettled == false` | A permissionless retry function or updated gas limit can be invoked to retry callback. |
| **Exhausted Reactive REACT** | Lasna fails to invoke `react()` | System contract halts subscription triggers | Deployer or community sends REACT to `AjoSettlementReactive`. |
| **Temporary Network Outage** | Relayer latency between Lasna and Base Sepolia | Payout delayed until cross-chain relay catches up | Event is persisted on Base Sepolia. Once network recovers, Reactive relayer processes log. |

---

## 4. Idempotency & Double-Payout Prevention

In any retry scenario:
- `AjoCircleManager.settleRound` performs a strict check:
  ```solidity
  if (!round.isFunded) revert RoundNotFunded();
  if (round.isSettled) revert RoundAlreadySettled();
  ```
- Because `round.isSettled` is set to `true` inside the same atomic execution as the `safeTransfer`, a retried callback will safely revert without transferring any duplicate funds.
- User balances are never redirectable. The protocol does not include administrative withdrawal or emergency redirection functions.
