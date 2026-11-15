# AjoFlow Phase 2 Architecture Specification

## 1. System Topology & Contract Separation

AjoFlow decouples cross-chain reactive monitoring from core financial settlement across three distinct smart contracts:

```mermaid
flowchart TD
    subgraph BaseSepolia["Base Sepolia (Destination & Settlement - Chain ID: 84532)"]
        Manager["AjoCircleManager.sol<br/>• Canonical state of circles & rounds<br/>• SafeERC20 USDC transfers<br/>• Restricted settleRound()"]
        Receiver["AjoSettlementReceiver.sol<br/>• Inherits AbstractCallback<br/>• Authorized Callback Proxy<br/>• onlyCallbackSender(reactive)"]
        USDC["Official Circle USDC<br/>0x036CbD53842c5426634e7929541eC2318f3dCF7e"]
        Proxy["Reactive Callback Proxy<br/>0x476F44b11F5C942c58f4c8E3d0300E5710743585"]
    end

    subgraph ReactiveLasna["Reactive Lasna (Orchestration - Chain ID: 5318007)"]
        System["Reactive SYSTEM Contract<br/>0x8888888888888888888888888888888888888888"]
        Reactive["AjoSettlementReactive.sol<br/>• Inherits AbstractReactive<br/>• Subscribes to RoundFunded<br/>• Deduplication check<br/>• requestCallbackV_1_0()"]
    end

    Manager -- "Emits RoundFunded" --> System
    System -- "react(LogRecord)" --> Reactive
    Reactive -- "requestCallbackV_1_0()" --> System
    System -. "Cross-Chain Relaying" .-> Proxy
    Proxy -- "executeSettlement(reactiveSender, circleId, roundIndex)" --> Receiver
    Receiver -- "settleRound(circleId, roundIndex)" --> Manager
    Manager -- "safeTransfer(recipient, totalPayout)" --> USDC
```

---

## 2. Rationale for Three-Contract Architecture

### A. Critical Inheritance Incompatibility
Reactive Omni enforces two distinct base contracts:
1. `AbstractReactive`: Inherits `AbstractPayer` initialized with `SYSTEM` (`0x8888888888888888888888888888888888888888`) on Lasna.
2. `AbstractCallback`: Inherits `AbstractPayer` initialized with `callbackProxy_` (`0x476F44b11F5C942c58f4c8E3d0300E5710743585`) on destination chains (Base Sepolia).

These two base contracts cannot be combined into a single contract. Their service-provider interfaces, payment routing, and modifier configurations address different networks and environments.

### B. Decoupled Security Perimeter
By separating `AjoCircleManager` from `AjoSettlementReceiver`:
- `AjoCircleManager` has zero dependency on cross-chain infrastructure; its attack surface is restricted to ordinary ERC-20 transfers and caller authorization.
- `AjoSettlementReceiver` acts as an authenticated perimeter bridge. Even if the receiver contract were corrupted or redeployed, it cannot manipulate circle parameters, change round recipients, or withdraw funds arbitrarily. It can only signal `settleRound(circleId, roundIndex)` for rounds already verified as fully funded on-chain.

---

## 3. Network Interfaces & Addresses

| Network | Entity | Verified Address | Description |
| :--- | :--- | :--- | :--- |
| **Base Sepolia (84532)** | Circle USDC | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | Settlement asset (6 decimals) |
| **Base Sepolia (84532)** | Callback Proxy | `0x476F44b11F5C942c58f4c8E3d0300E5710743585` | Authorized callback execution relay |
| **Base Sepolia (84532)** | `AjoCircleManager` | `PENDING (Phase 3)` | Core state machine & vault |
| **Base Sepolia (84532)** | `AjoSettlementReceiver`| `PENDING (Phase 3)` | Callback receiver |
| **Reactive Lasna (5318007)** | System Contract | `0x8888888888888888888888888888888888888888` | Omni subscription & callback engine |
| **Reactive Lasna (5318007)** | `AjoSettlementReactive`| `PENDING (Phase 3)` | Event listener & callback requester |
