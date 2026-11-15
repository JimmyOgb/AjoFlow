# AjoFlow

> **Autonomous, Zero-Maintenance Rotating Savings & Credit Protocol powered by Reactive Omni**

Built for the **Reactive Omni Buildathon** (Track: *Set It and Forget It*) on [DoraHacks](https://dorahacks.io/hackathon/reactive-omni-buildathon/detail).

---

## 1. Problem & Solution

### The Problem
Traditional Rotating Savings and Credit Associations (ROSCAs, known globally as *Ajo*, *Esusu*, *Tanda*, or *Chit funds*) help billions of people save collectively. However, existing implementations suffer from:
- **Centralized Coordinator Risk:** The circle manager can abscond with funds, delay payouts, or charge arbitrary fees.
- **Fragile Web3 Automation:** Smart contract ROSCAs previously depended on centralized off-chain keepers (e.g. Gelato, Chainlink Automation) or manual triggers, requiring recurring fees, server maintenance, and multi-signature monitoring.

### The Solution: AjoFlow
AjoFlow implements fully autonomous on-chain ROSCAs using **Reactive Omni**:
1. Members pool fixed amounts of verified Circle USDC on Base Sepolia.
2. An autonomous Reactive contract on Reactive Lasna monitors deposit milestones directly from event logs.
3. Upon cycle round completion, the Reactive contract automatically dispatches a cross-chain callback to execute payouts to the scheduled recipient without human or centralized keeper intervention.

---

## 2. Target Users

- **Collaborative Savers:** Communities and peer circles seeking transparent, trustless rotating savings pools.
- **DeFi Micro-savers:** Users wanting automated capital accumulation in stablecoins (Circle USDC) on low-fee L2 networks (Base Sepolia).
- **Decentralized Finance Enthusiasts:** Developers and users looking for pure *set-and-forget* financial automations.

---

## 3. Why Reactive Network is Essential

In traditional Ethereum smart contracts, logic cannot execute on its own without an external transaction (EOA) initiating and paying gas. 

With **Reactive Omni**:
- **Inversion of Control:** The smart contract natively listens to event logs across chains.
- **Autonomous Feedback Loop:** Once subscribed, the contract reacts to events and triggers cross-chain callbacks when conditions are met.
- **Sub-Second Finality:** Reactive Omni's CometBFT consensus provides instant finality (~1 second block times), ensuring rapid execution for time-sensitive rotation schedules.

---

## 4. Architecture & Event-to-Callback Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Member as Circle Member
    participant Vault as AjoFlowPool (Base Sepolia)
    participant Proxy as Callback Proxy (Base Sepolia)
    participant System as SYSTEM Contract (Lasna)
    participant Reactive as AjoFlowReactive (Lasna)

    Member->>Vault: deposit(circleId, roundIndex) with USDC
    Vault-->>System: Log Emitted: ContributionReceived
    System->>Reactive: react(LogRecord)
    Note over Reactive: Evaluates round completion threshold
    Reactive->>System: requestCallbackV_1_0(executePayout)
    System->>Proxy: Forward Callback Execution
    Proxy->>Vault: executePayout(reactiveSender, circleId, recipient)
    Note over Vault: Validates onlyServiceProvider & onlyCallbackSender
    Vault->>Member: Disburses total round USDC pool to scheduled recipient
```

---

## 5. Contract Responsibilities

| Contract | Network | Compiler | Role & Key Responsibilities |
| :--- | :--- | :--- | :--- |
| **`AjoFlowPool.sol`** | Base Sepolia (`84532`) | Solidity `0.8.29` | **Settlement Vault & Callback Consumer.** Inherits `AbstractCallback`. Manages USDC deposits, validates member participation, enforces `onlyServiceProvider` and `onlyCallbackSender`, and distributes round payouts. |
| **`AjoFlowReactive.sol`** | Reactive Lasna (`5318007`) | Solidity `0.8.29` | **Autonomous Orchestrator.** Inherits `AbstractReactive`. Subscribes to Base Sepolia deposit events, computes rotation schedules, and invokes `SYSTEM.requestCallbackV_1_0()`. |

---

## 6. Verified Network Configuration

All live network RPC endpoints and contracts were inspected and verified via read-only RPC calls during Phase 1 reconnaissance.

### Base Sepolia (Chain ID `84532`)
- **RPC Endpoint:** `https://sepolia.base.org` (Verified active)
- **Settlement Token:** Circle USDC at `0x036CbD53842c5426634e7929541eC2318f3dCF7e` (6 decimals verified)
- **Callback Proxy:** `0x476F44b11F5C942c58f4c8E3d0300E5710743585` (Bytecode verified)
- **Block Explorer:** [https://sepolia.basescan.org](https://sepolia.basescan.org)

### Reactive Lasna (Chain ID `5318007`)
- **RPC Endpoint:** `https://lasna-rpc.rnk.dev/` (Verified active)
- **System Contract:** `0x8888888888888888888888888888888888888888` (Bytecode verified)
- **Block Explorer:** [https://lasna.reactscan.net](https://lasna.reactscan.net)

---

## 7. Frontend User Interface Design

The frontend user interface follows the production reference design documented in [`docs/architecture/ui-reference.png`](docs/architecture/ui-reference.png):
- **Circle Discovery & My Groups:** High-level summary of active circles, contribution progress bars (e.g. 4 of 6 paid), and upcoming deadlines.
- **Cycle Details Dashboard:** Balance display, dynamic round progress stepper (rounds 1 through 8), and draw schedules.
- **Member Transparency View:** Granular member status indicators (*Paid*, *Late*, *Pending*).

---

## 8. Technology Stack

- **Smart Contracts:** Solidity `^0.8.29`
- **Reactive Library:** Reactive Omni (`@reactive-network/reactive-lib-omni`)
- **Build & Test Tools:** Foundry / Hardhat & Node.js
- **Settlement Token:** Official Circle USDC (EIP-3009 / ERC-20, 6 decimals)
- **Frontend:** Next.js / Tailwind CSS / Viem & Wagmi

---

## 9. Setup Instructions

```bash
# Clone the repository
git clone https://github.com/JimmyOgb/AjoFlow.git
cd AjoFlow

# Inspect project foundation
ls -la

# Copy environment variables template
cp .env.example .env
```

---

## 10. Environment Variable Reference

See [`.env.example`](.env.example) for the full configuration reference:
- `BASE_SEPOLIA_RPC`: Base Sepolia RPC URL
- `LASNA_RPC`: Reactive Lasna RPC URL
- `BASE_SEPOLIA_USDC`: Official Circle USDC address (`0x036CbD53842c5426634e7929541eC2318f3dCF7e`)
- `BASE_SEPOLIA_CALLBACK_PROXY`: Callback proxy (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`)
- `LASNA_SYSTEM_CONTRACT`: System contract (`0x8888888888888888888888888888888888888888`)

---

## 11. Security Model & Economic Rules

- **Strict Access Control:** Callbacks can only be initiated by the designated Reactive Contract via the verified Callback Proxy.
- **Debt Prohibition:** Under Reactive Omni, contracts with positive debt are halted by the system contract. Both contracts maintain autonomous gas reserves to immediately settle execution charges.
- **Address Injection Invariant:** Callbacks format payloads with `address(0)` in the first position to ensure cryptographic injection of the authenticated reactive sender.

---

## 12. Actual Implementation Status

- [x] **Phase 1: Repository Creation, Technical Reconnaissance and Foundation** (Completed)
  - [x] Public repository created under authenticated account (`JimmyOgb/AjoFlow`)
  - [x] Live read-only RPC reconnaissance on Base Sepolia and Reactive Lasna
  - [x] Circle USDC and System Contract bytecode confirmed
  - [x] Architectural documentation and security specifications completed
- [ ] **Phase 2: Contract Implementation & Local/Testnet Testing** (Pending Phase 1 Review)
- [ ] **Phase 3: Live Testnet Deployment & Event Feedback Loop Execution** (Pending Phase 2)
- [ ] **Phase 4: Frontend Integration, Video Demonstration & Final Submission** (Pending Phase 3)

### Verified Addresses and Hashes Status:
- `AjoFlowPool` (Base Sepolia): `PENDING`
- `AjoFlowReactive` (Reactive Lasna): `PENDING`
- Origin Deposit Transaction Hash: `PENDING`
- Lasna Reaction Transaction Hash: `PENDING`
- Callback Execution Transaction Hash: `PENDING`

---

## 13. Three-Minute Demo Plan

1. **Minute 0:00 - 0:45 (Problem & Architecture):** Explain the vulnerability of traditional ROSCAs and present the AjoFlow architecture showing how Reactive Omni automates savings circles.
2. **Minute 0:45 - 1:45 (Live Interaction & Deposit):** Connect wallet on Base Sepolia, display the group dashboard, and deposit USDC for the current round.
3. **Minute 1:45 - 2:30 (Autonomous Reactive Execution):** Show the Lasna block explorer capturing the contribution event and automatically triggering `requestCallbackV_1_0`.
4. **Minute 2:30 - 3:00 (On-Chain Settlement Confirmation):** Verify the callback execution on Base Sepolia and the automated USDC payout disbursement to the recipient without any manual keeper interaction.

---

## 14. License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.
