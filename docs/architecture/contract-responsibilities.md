# AjoFlow Contract Responsibilities & Technical Interfaces

This document outlines the responsibilities, interfaces, and security roles for each smart contract in the AjoFlow architecture.

## 1. Destination / Settlement Contract: `AjoFlowPool.sol`

- **Network:** Base Sepolia (Chain ID `84532`)
- **Base Contract:** Inherits `AbstractCallback`
- **Compiler Version:** Solidity `^0.8.29`
- **Callback Proxy:** `0x476F44b11F5C942c58f4c8E3d0300E5710743585`
- **Settlement Token:** Circle USDC (`0x036CbD53842c5426634e7929541eC2318f3dCF7e`)

### Responsibilities:
1. **Circle Lifecycle:** Register circles with fixed member counts, periodic contribution amounts (in USDC with 6 decimals), and scheduled payout order.
2. **Deposit Accounting:** Allow members to submit scheduled USDC contributions. Emits `ContributionReceived` log upon each valid transfer.
3. **Autonomous Payout:** Receive callback transactions triggered by the Reactive Network to disburse the accumulated round balance to the scheduled recipient.
4. **Authentication:** Restrict callback execution strictly via `onlyServiceProvider` (Callback Proxy) and `onlyCallbackSender` (authorized Reactive Contract).
5. **Fee Settlement:** Hold native gas reserves to settle callback execution fees with the Callback Proxy via `_coverDebt()`.

---

## 2. Autonomous Orchestrator: `AjoFlowReactive.sol`

- **Network:** Reactive Lasna (Chain ID `5318007`)
- **Base Contract:** Inherits `AbstractReactive`
- **Compiler Version:** Solidity `^0.8.29`
- **System Contract:** `0x8888888888888888888888888888888888888888`

### Responsibilities:
1. **Event Subscription:** Subscribe at initialization via `SYSTEM.subscribe()` to events emitted by `AjoFlowPool` on Base Sepolia (`chainId: 84532`).
2. **Autonomous Trigger Processing:** In `react(LogRecord calldata log_)`, decode incoming contribution events and evaluate round progression criteria.
3. **Callback Dispatch:** Call `SYSTEM.requestCallbackV_1_0()` using `ISystemContract.CallbackConfiguration_V_1_0` to dispatch a callback payload back to Base Sepolia.
4. **Security Convention:** Format callback payloads with `address(0)` in the first argument position so the Reactive Callback Proxy securely injects the reactive contract caller address.
5. **Funding Maintenance:** Maintain sufficient native REACT balance to cover system contract execution costs.
