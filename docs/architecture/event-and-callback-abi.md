# AjoFlow Event & Callback ABI Specification

This document details the exact cryptographic signatures, topic mappings, and ABI payloads exchanged across Base Sepolia and Reactive Lasna.

---

## 1. Event Definitions & Topic Signatures

### `RoundFunded` (Reactive Trigger Event)
- **Signature:** `RoundFunded(uint256,uint256,address,uint256)`
- **`topic0` Hash:** `0x52f68a3a7909db0977c03511ae375412cccb31b41a9cfcb8d6d2678e7d96255a`

#### Topic & Data Mapping in `LogRecord`:
```solidity
event RoundFunded(
    uint256 indexed circleId,    // topic1
    uint256 indexed roundIndex,   // topic2
    address indexed recipient,    // topic3 (padded to 32 bytes)
    uint256 totalAmount           // data (unindexed 32-byte integer)
);
```

| Field | Source in `LogRecord` | EVM Representation |
| :--- | :--- | :--- |
| `topic0` | `log_.topic0` | `0x52f68a3a7909db0977c03511ae375412cccb31b41a9cfcb8d6d2678e7d96255a` |
| `circleId` | `log_.topic1` | `uint256` |
| `roundIndex` | `log_.topic2` | `uint256` |
| `recipient` | `log_.topic3` | `address(uint160(log_.topic3))` |
| `totalAmount` | `log_.data` | `abi.decode(log_.data, (uint256))` |

---

### Supporting Events
| Event | Signature | `topic0` Keccak-256 Hash |
| :--- | :--- | :--- |
| `CircleCreated` | `CircleCreated(uint256,address,uint256,uint256,uint256)` | `0x4672cb99634a1f562714ec9a87b8cd43a23b598ab7b87c86d3fbb61a3e6d2a42` |
| `MemberJoined` | `MemberJoined(uint256,address,uint256)` | `0xf4f82575ee84a81aac4be52b6a368e9ba9df524b4f5cf8177d7cfbabe861820c` |
| `ContributionReceived` | `ContributionReceived(uint256,address,uint256,uint256)` | `0xd2d33c5340520954ae03d46ba5f056dd7adb35260f86df538a709bed96d89afb` |
| `RoundSettled` | `RoundSettled(uint256,uint256,address,uint256)` | `0xdb25702c8603deec7f184be4ebefac490555e5c3d74e67817e74d4db7f89d00a` |
| `SettlementTriggered` | `SettlementTriggered(uint256,uint256,address)` | `0xb5e76a6cf06a8f17a942fa6da72273087a329d2f785b9679f29bf8b5a04ef9a5` |

---

## 2. Callback Payload Construction & Decoding

### Callback Function
```solidity
function executeSettlement(
    address reactiveSender,
    uint256 circleId,
    uint256 roundIndex
) external;
```
- **Function Signature:** `executeSettlement(address,uint256,uint256)`
- **Selector (4 bytes):** `0x79df16b0`

### Reactive Contract Construction (Reactive Lasna)
When requesting the callback via `SYSTEM.requestCallbackV_1_0()`:
```solidity
bytes memory payload = abi.encodeWithSelector(
    IAjoSettlementReceiver.executeSettlement.selector,
    address(0),  // Injected by Callback Proxy on Base Sepolia
    circleId,
    roundIndex
);
```

### Callback Proxy Injection (Base Sepolia)
When `0x476F44b11F5C942c58f4c8E3d0300E5710743585` executes the callback on `AjoSettlementReceiver`, it replaces the first parameter (`address(0)`) with the authenticated address of `AjoSettlementReactive`.

---

## 3. Illustrative Worked ABI Encoding

> [!NOTE]
> The values below are **purely illustrative test vectors** provided to document byte-level alignment. They do not represent live transactions or deployed state.

Suppose:
- `circleId` = `1` (`0x0000000000000000000000000000000000000000000000000000000000000001`)
- `roundIndex` = `1` (`0x0000000000000000000000000000000000000000000000000000000000000001`)

### Reactive Request Payload (96 bytes):
```text
0x79df16b0                                                         // Selector: executeSettlement
  0000000000000000000000000000000000000000000000000000000000000000  // Param 1: address(0) placeholder
  0000000000000000000000000000000000000000000000000000000000000001  // Param 2: circleId (1)
  0000000000000000000000000000000000000000000000000000000000000001  // Param 3: roundIndex (1)
```

### Injected Calldata Delivered to Receiver:
Assuming hypothetical reactive contract address `0x1111111111111111111111111111111111111111`:
```text
0x79df16b0                                                         // Selector: executeSettlement
  0000000000000000000000001111111111111111111111111111111111111111  // Param 1: Authenticated sender
  0000000000000000000000000000000000000000000000000000000000000001  // Param 2: circleId (1)
  0000000000000000000000000000000000000000000000000000000000000001  // Param 3: roundIndex (1)
```
The modifier `onlyCallbackSender(reactiveSender)` checks `reactiveSender == _CALLBACK_SENDER`.
