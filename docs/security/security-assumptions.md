# AjoFlow Security Assumptions & Threat Model

This document outlines the security model, cryptographic invariants, and operational assumptions governing the AjoFlow protocol.

## 1. Access Control & Callback Authentication

1. **Callback Proxy Isolation:** Destination callback functions in `AjoFlowPool` are protected by the `onlyServiceProvider` modifier, ensuring that callbacks can originate solely from the verified Reactive Callback Proxy (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`).
2. **Caller Identity Verification:** Destination callback functions implement the `onlyCallbackSender` modifier, verifying that the injected sender address matches the designated `AjoFlowReactive` contract on Lasna.
3. **Payload Sanitization:** Reactive callbacks strictly place `address(0)` in the first position of encoded payloads, preventing spoofing of the calling contract identity.

## 2. Economic & Gas Assumptions

1. **Solvency and Debt Prevention:**
   - Under Reactive Omni, contracts with outstanding debt are blocked from executing subsequent reactions or callbacks.
   - Both `AjoFlowPool` on Base Sepolia and `AjoFlowReactive` on Lasna must maintain sufficient native token reserves (Base Sepolia ETH and Lasna REACT) to immediately clear service debts.
2. **Deterministic Token Transfers:**
   - Accounting is denominated in Circle USDC with exactly 6 decimals.
   - Payout calculations avoid floating point division loss.

## 3. Threat Matrix & Mitigations

| Threat | Vulnerability Vector | Mitigation |
| :--- | :--- | :--- |
| **Unauthorized Callback** | Malicious actor calls payout endpoint directly | Guarded by `onlyServiceProvider` and `onlyCallbackSender` checks |
| **Reentrancy Attack** | Re-entrant call during payout token transfer | State updates precede external ERC-20 transfers (Checks-Effects-Interactions) |
| **Indebted Silence** | Zero gas reserve blocks callback delivery | Proactive funding thresholds and monitoring before round deadlines |
| **Front-running Payouts** | Ordering manipulation of member contributions | Strict round index validation and idempotent payout state flags |
