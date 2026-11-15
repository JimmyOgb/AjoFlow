# AjoFlow Acceptance Test Plan & Evidence Categories

To guarantee absolute integrity, AjoFlow defines three strictly decoupled testing tiers. Local simulation is never conflated with live cross-chain verification.

---

## Tier A: Static & Local Deterministic Checks
*Executed in Phase 2 development environment.*

- **Scope:** Compilation, interface conformance, static analysis, gas estimation, formatting.
- **Tools:** Hardhat 3.22, Solc 0.8.29, Solhint, Prettier.
- **Evidence Produced:**
  - Compiler artifacts in `artifacts/`.
  - Zero compiler errors, zero Solhint syntax errors.
  - Byte-level topic0 hash verification (`0x52f68a3a...` for `RoundFunded`).
- **Limitation:** Does not prove blockchain connectivity, network consensus, or callback delivery.

---

## Tier B: Local Development Unit & State Tests
*Scheduled for Phase 3 local test development.*

- **Scope:** Hardhat local EVM testing of state machine transitions.
- **Test Scenarios:**
  1. Circle creation and member joining (1 to 3 members).
  2. Contribution state validation and SafeERC20 balances.
  3. Quorum detection and `RoundFunded` event firing.
  4. Restricted caller authorization on `settleRound()`.
  5. Reentrancy and duplicate contribution rejection.
- **Evidence Labeling:** Strictly labeled as **LOCAL-ONLY**.
- **Limitation:** Local mock contracts or simulated events do NOT represent real Circle USDC transfers or real Reactive Network execution.

---

## Tier C: Live On-Chain Acceptance Flow
*Reserved exclusively for authorized live testnet verification.*

A test run qualifies as verified cross-chain proof if and only if it executes across live public networks with the following sequence:

1. **Three Independent User Accounts:** Three separate external wallets (Member 1, Member 2, Member 3).
2. **Real Circle USDC:** Actual ERC-20 approvals and transfers of Circle USDC (`0x036CbD53842c5426634e7929541eC2318f3dCF7e`) on Base Sepolia (`84532`).
3. **Live Base Sepolia Event:** `AjoCircleManager` emits `RoundFunded` upon 3rd contribution.
4. **Autonomous Reactive Interception:** `AjoSettlementReactive` on Reactive Lasna (`5318007`) intercepts the log via `SYSTEM` and triggers `react()`.
5. **Cross-Chain Callback Execution:** Reactive Callback Proxy (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`) delivers callback to `AjoSettlementReceiver` on Base Sepolia.
6. **Automated Payout Disbursement:** `AjoCircleManager` disburses accumulated USDC pool to the scheduled recipient.
7. **Verifiable Proof:** Real transaction hashes on [sepolia.basescan.org](https://sepolia.basescan.org) and [lasna.reactscan.net](https://lasna.reactscan.net).
