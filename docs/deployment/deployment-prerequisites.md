# AjoFlow Deployment Prerequisites & Execution Order

This guide defines the prerequisites, accounts, and verified sequencing required for deploying AjoFlow to testnet environments.

## 1. Network & Tooling Prerequisites

- **Solidity Version:** `^0.8.29` (enforced by Reactive Omni specifications)
- **Node.js:** `>= 20.x`
- **Foundry / Hardhat:** EVM compilation and script execution environment
- **Reactive Omni Dependencies:** Interface definitions from `reactive-lib-omni`

## 2. Live Network Parameters

### Base Sepolia
- **Chain ID:** `84532`
- **RPC:** `https://sepolia.base.org`
- **Callback Proxy:** `0x476F44b11F5C942c58f4c8E3d0300E5710743585`
- **Circle USDC:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **Required Faucet Funding:** Base Sepolia ETH (for deployment and callback reserves) + testnet USDC

### Reactive Lasna
- **Chain ID:** `5318007`
- **RPC:** `https://lasna-rpc.rnk.dev/`
- **System Contract:** `0x8888888888888888888888888888888888888888`
- **Required Faucet Funding:** Lasna REACT (for deployment and reactive execution reserves)

---

## 3. Mandatory Deployment Sequence

1. **Step 1 — Destination Deployment (Base Sepolia):**
   - Deploy `AjoFlowPool` targeting Base Sepolia.
   - Initial parameters: Callback Proxy address (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`) and Circle USDC address (`0x036CbD53842c5426634e7929541eC2318f3dCF7e`).
   - Fund deployed `AjoFlowPool` with initial native ETH for callback proxy gas coverage.

2. **Step 2 — Orchestrator Deployment (Reactive Lasna):**
   - Deploy `AjoFlowReactive` targeting Lasna.
   - Initial parameters: `AjoFlowPool` address on Base Sepolia and Base Sepolia Chain ID (`84532`).
   - Fund deployed `AjoFlowReactive` with native REACT for system contract transaction charges.

3. **Step 3 — Authorization Handshake:**
   - On Base Sepolia, configure or verify the authorized reactive callback sender address in `AjoFlowPool`.
   - On Lasna, confirm active event subscription via the Lasna block explorer.
