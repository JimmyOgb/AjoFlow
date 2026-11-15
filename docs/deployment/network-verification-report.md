# AjoFlow Phase 1 Live Network Verification Report

This report documents the live, read-only JSON-RPC reconnaissance performed on target networks for the AjoFlow protocol.

## 1. Base Sepolia (Destination & Settlement Chain)

- **RPC Endpoint:** `https://sepolia.base.org`
- **Chain ID:** `84532` (`0x14a34` verified)
- **Check Timestamp:** `2026-11-15T04:04:45.784203Z`
- **Status:** Active & Verified

### Contract Verifications
1. **Official Circle USDC:**
   - Address: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
   - Bytecode Size: 3,598 hex characters (verified deployed)
   - Token Name: `USDC` (call `0x06fdde03`)
   - Token Symbol: `USDC` (call `0x95d89b41`)
   - Decimals: `6` (call `0x313ce567`)

2. **Reactive Callback Proxy:**
   - Address: `0x476F44b11F5C942c58f4c8E3d0300E5710743585`
   - Bytecode Size: 438 hex characters (verified deployed)

---

## 2. Reactive Lasna (Autonomous Reactive Orchestration Chain)

- **RPC Endpoint:** `https://lasna-rpc.rnk.dev/`
- **Chain ID:** `5318007` (`0x512577` verified)
- **Check Timestamp:** `2026-11-15T04:04:49.514653Z`
- **Latest Block Number:** `8380803` (`0x7fdd83`)
- **Status:** Active & Responsive

### Contract Verifications
1. **Reactive System Contract:**
   - Address: `0x8888888888888888888888888888888888888888`
   - Bytecode Size: 480 hex characters (verified deployed)
   - Functionality: Event subscription management (`subscribe`, `unsubscribe`) and callback scheduling (`requestCallbackV_1_0`).

---

## 3. Discrepancy & Verification Summary

- No network RPC discrepancies detected. All chain IDs, bytecode checks, and token parameters matched official specifications.
- Settlement token configuration strictly confirmed as Circle USDC (6 decimals). No mock tokens or unverified proxies were used.
