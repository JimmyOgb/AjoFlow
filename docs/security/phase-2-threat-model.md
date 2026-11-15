# AjoFlow Phase 2 Threat Model & Security Review

This document provides a rigorous vulnerability assessment for the AjoFlow protocol, distinguishing verified architectural designs from risks requiring concrete implementation testing in Phase 3.

---

## 1. Architectural Mitigations vs. Implementation Testing Status

| Threat Category | Potential Attack Vector | Architectural Mitigation | Verification Status |
| :--- | :--- | :--- | :--- |
| **Reentrancy** | Malicious recipient contract attempts re-entry during USDC payout | `ReentrancyGuard` applied on all state-mutating functions; Checks-Effects-Interactions strictly applied. | **DESIGN RESOLVED** — *Implementation Testing Pending (Phase 3 unit tests)* |
| **ERC-20 Token Behavior** | Non-standard return values, fee-on-transfer, or silent reverts | OpenZeppelin `SafeERC20` used for all transfers. Protocol pinned strictly to official Circle USDC (6 decimals). | **DESIGN RESOLVED** — *Mock/Fork Integration Testing Pending (Phase 3)* |
| **Duplicate Contributions** | A member submits multiple payments for a single round | `_contributions[circleId][roundIndex][msg.sender]` boolean flag checked and set prior to transfer. | **DESIGN RESOLVED** — *State Transition Test Pending (Phase 3)* |
| **Duplicate Event Processing** | Reactive network processes same event multiple times | `processedRounds[circleId][roundIndex]` mapping in `AjoSettlementReactive` drops duplicate triggers. | **DESIGN RESOLVED** — *Reactive Trigger Test Pending (Phase 3)* |
| **Duplicate Callbacks** | Redundant callbacks delivered to Base Sepolia receiver | `AjoCircleManager.settleRound` checks `round.isSettled` and idempotently returns `false` without re-transferring funds or reverting. | **DESIGN RESOLVED** — *Idempotency Test Pending (Phase 3)* |
| **Arbitrary Amount / Recipient Injection** | Malicious calldata specifies false payout amount or diverted recipient | Calldata in `settleRound(circleId, roundIndex)` contains only identifiers. Recipient and amount are read exclusively from internal manager storage. | **DESIGN RESOLVED** — *Access Control Test Pending (Phase 3)* |
| **Payout Order Mutation** | Front-running or reordering of recipient list | Member list is immutable once 3 members join. Round recipient is deterministically hardcoded as `members[roundIndex - 1]`. | **DESIGN RESOLVED** — *Ordering Integrity Test Pending (Phase 3)* |
| **Premature Settlement** | Settlement triggered before all 3 members contribute | `settleRound()` requires `round.isFunded == true`, which is only set when `contributionsCount == maxMembers`. | **DESIGN RESOLVED** — *Quorum Enforcement Test Pending (Phase 3)* |
| **Unauthorized Callback Sender** | Unrelated reactive contract invokes receiver | Receiver enforces `onlyCallbackSender(reactiveSender)` matching immutable `_CALLBACK_SENDER`. | **DESIGN RESOLVED** — *Cross-Contract Auth Test Pending (Phase 3)* |
| **Direct Receiver Bypass** | Attacker invokes receiver directly without proxy | Receiver enforces `onlyServiceProvider` checking `msg.sender == address(_SERVICE_PROVIDER)`. | **DESIGN RESOLVED** — *Modifier Revert Test Pending (Phase 3)* |
| **Token Decimal Mismatch** | Protocol assumes 18 decimals instead of USDC's 6 decimals | Accounting uses actual token units (`contributionAmount` stored in 6-decimal units). All calculations verified with USDC precision. | **DESIGN RESOLVED** — *Decimal Precision Test Pending (Phase 3)* |
| **Invalid Circle / Round IDs** | Out-of-bounds or non-existent circle references | Explicit validation: `circle.circleId != 0`, `state == Active`, `roundIndex == circle.currentRound`. | **DESIGN RESOLVED** — *Boundary Value Test Pending (Phase 3)* |

---

## 2. Unresolved Risks & Operational Considerations

The following risks **cannot be verified by design alone** and remain unresolved until comprehensive testing in Phase 3:

1. **Callback Gas Exhaustion:** If the gas limit provided in `requestCallbackV_1_0` (`300,000` gas) is insufficient under unforeseen Base Sepolia gas repricing or complex storage writes, the callback may fail on destination.
2. **Asymmetric Network Gas Spike:** Sudden base fee spikes on Base Sepolia could rapidly deplete the callback receiver's ETH reserve, accumulating debt with the Callback Proxy and temporarily blocking subsequent callbacks.
3. **Reactive Network Relayer Latency:** Temporary network congestion between Lasna consensus and Base Sepolia could delay round settlement.
4. **Member Abandonment / Default:** In a 3-member circle, if a member stops contributing after receiving their payout in Round 1, subsequent rounds cannot reach quorum without an explicit default/forfeiture mechanism.

---

## 3. Mandatory Pre-Deployment Gate Criteria

Before any contract is deployed to live testnets in Phase 3, the following gates must be passed:
- [ ] 100% passing automated local test suite covering all state transitions in `AjoCircleManager`.
- [ ] Reentrancy attack simulation tests verifying that reentrant payout attempts fail.
- [ ] Unauthorized caller exploit tests confirming that non-proxy and non-reactive callers cannot trigger settlements.
- [ ] Callback idempotency simulation confirming that back-to-back callback invocations do not duplicate payouts or revert.
- [ ] Gas profiling demonstrating `executeSettlement` execution comfortably beneath the configured gas limit.
- [ ] Live faucet funding confirmation for deployer wallets on both Base Sepolia and Lasna.
