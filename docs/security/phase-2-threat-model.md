# AjoFlow Phase 2 Threat Model & Security Review

This document provides a comprehensive security review and vulnerability assessment for the AjoFlow protocol.

---

## 1. Vulnerability Matrix & Mitigations

| Threat Category | Potential Attack Vector | Architectural Mitigation | Status |
| :--- | :--- | :--- | :--- |
| **Reentrancy** | Malicious recipient contract re-enters during USDC payout | `ReentrancyGuard` applied on all state-mutating functions (`createCircle`, `joinCircle`, `contribute`, `settleRound`). Checks-Effects-Interactions strictly applied. | **RESOLVED** |
| **ERC-20 Inconsistencies** | Non-standard token return values or reverts | OpenZeppelin `SafeERC20` used for all `safeTransfer` and `safeTransferFrom` operations. | **RESOLVED** |
| **Duplicate Contributions** | A member attempts to submit multiple payments for a single round | `_contributions[circleId][roundIndex][msg.sender]` boolean flag checked and set prior to token transfer. Reverts with `AlreadyContributed()`. | **RESOLVED** |
| **Duplicate Event Processing** | Reactive network processes same event multiple times | `processedRounds[circleId][roundIndex]` mapping in `AjoSettlementReactive` ensures idempotent reaction; duplicate triggers safely early-return. | **RESOLVED** |
| **Duplicate Callbacks** | Redundant callbacks delivered to Base Sepolia receiver | `AjoCircleManager.settleRound` checks `round.isSettled == false` before state modification and transfer. Redundant attempts revert with `RoundAlreadySettled()`. | **RESOLVED** |
| **Arbitrary Amount / Recipient Injection** | Malicious calldata specifies false payout amount or diverted recipient | Calldata in `settleRound(circleId, roundIndex)` contains only identifiers. Recipient and amount are read exclusively from internal manager storage. | **RESOLVED** |
| **Payout Order Mutation** | Front-running or reordering of recipient list | Member list is immutable once 3 members join. Round recipient is deterministically hardcoded as `members[roundIndex - 1]`. | **RESOLVED** |
| **Premature Settlement** | Settlement triggered before all 3 members contribute | `settleRound()` requires `round.isFunded == true`, which is only set when `contributionsCount == maxMembers`. | **RESOLVED** |
| **Unauthorized Callback Sender** | Unrelated reactive contract invokes receiver | Receiver enforces `onlyCallbackSender(reactiveSender)` matching immutable `_CALLBACK_SENDER`. | **RESOLVED** |
| **Direct Receiver Bypass** | Attacker invokes receiver directly without proxy | Receiver enforces `onlyServiceProvider` checking `msg.sender == address(_SERVICE_PROVIDER)`. | **RESOLVED** |
| **Token Decimal Mismatch** | Protocol assumes 18 decimals instead of USDC's 6 decimals | Accounting uses actual token units (`contributionAmount` stored in 6-decimal units). All calculations verified with USDC precision. | **RESOLVED** |
| **Invalid Circle / Round IDs** | Out-of-bounds or non-existent circle references | Explicit validation: `circle.circleId != 0`, `state == Active`, `roundIndex == circle.currentRound`. | **RESOLVED** |

---

## 2. Invariant Checklist

1. **Vault Solvency:** At any point during round $R$, the manager's USDC balance equals the accumulated contributions of un-settled rounds.
2. **Deterministic Settlement:** Each round settles at most once.
3. **No Unilateral Fund Redirection:** No administrator, owner, or callback caller possesses the capability to alter payout beneficiaries or withdraw pooled user balances.
