# AjoFlow Toolchain & Dependency Lock

This document specifies the exact developer toolchain, pinned dependencies, and compiler settings selected for AjoFlow.

---

## 1. Toolchain Selection Rationale

### Environment Context
- Operating System: Windows 11
- Node.js Runtime: `v24.15.0`
- NPM Version: `11.12.1`
- Foundry Status: Foundry (`forge`/`cast`) was not present in the Windows system PATH during Phase 1 reconnaissance.

### Toolchain Decision: **Hardhat 3.22 (ESM) + Solc 0.8.29**
- **Native Cross-Platform Compatibility:** Hardhat runs directly in the existing Node.js environment on Windows without requiring manual WSL configuration or separate native binary installations.
- **WASM Solidity Compiler:** Hardhat manages the official Solidity `0.8.29` WASM build deterministically across platforms.
- **Standard Tooling Integration:** Native compatibility with OpenZeppelin Contracts v5, Prettier with Solidity plugin, and Solhint.

---

## 2. Pinned Dependency Versions

### `package.json` Manifest
```json
{
  "name": "ajoflow",
  "version": "1.0.0",
  "type": "module",
  "devDependencies": {
    "@openzeppelin/contracts": "^5.6.1",
    "hardhat": "^3.22.0",
    "prettier": "^3.10.1",
    "prettier-plugin-solidity": "^2.4.1",
    "solhint": "^6.2.5"
  }
}
```

### Reactive Omni Dependency
- **Source Repository:** `https://github.com/Reactive-Network/reactive-lib-omni`
- **Release Tag:** `v0.1.0`
- **Pinned Commit:** `3ade0dcf1d27e67e5783ef807e73a1b9e0c0cce8`
- **Vendored Location:** [`lib/reactive-lib-omni/`](../../lib/reactive-lib-omni/)
- **Compiler Compatibility:** `pragma solidity ^0.8.29;`

---

## 3. Compiler Configuration (`hardhat.config.js`)

```javascript
/** @type import('hardhat/config').HardhatUserConfig */
const config = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "cancun",
    },
  },
  paths: {
    sources: "./contracts/src",
    tests: "./contracts/test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
```

---

## 4. Setup & Verification Commands

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run Solhint static analysis
npx solhint "contracts/src/**/*.sol"

# Check code formatting
npx prettier --check "contracts/src/**/*.sol" "reactive/src/**/*.sol"
```
