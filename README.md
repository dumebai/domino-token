# 🧩 Domino Protocol - Cross-Chain Rebase Vault

Domino Protocol is a decentralized system that allows users to deposit ETH into a **Vault** and receive **rebase tokens** (`DOMINO`) that increase in value over time, incentivizing early participation. This is achieved via an interest-bearing token that dynamically adjusts user balances based on their individual interest rates, fixed at deposit time.

---

## 🚀 Key Features

- **Rebasing Token (`DOMINO`)**  
  Dynamic ERC20 token whose `balanceOf` increases linearly over time, per user-specific interest rate.

- **Vault Contract (`DominoVault`)**  
  Users deposit ETH and receive rebase tokens. They can also redeem tokens back into ETH anytime.

- **User-specific Interest**  
  Each user's interest rate is determined at deposit time, based on a global rate.  
  The **global rate can only decrease**, rewarding early adopters.

- **Accrued Interest On Interaction**  
  Interest is automatically minted when users mint, burn, transfer, or bridge tokens.

- **Modular Design**  
  Contracts are designed with upgradeability and cross-chain compatibility in mind.

---

## ⚙️ Getting Started

> Requires: [Foundry](https://book.getfoundry.sh/getting-started/installation) installed globally.

### 1. Install dependencies

```bash
forge install
```

### 2. Build contracts

```bash
forge build
```

### 3. Run tests

```bash
forge test
```

---

## 🧪 Tests

Tests are written using Foundry and are currently **in progress**.  
Expect full coverage soon including:

- Vault deposit & redeem flow  
- Rebase logic: interest accrual over time  
- Transfer logic with dynamic balance  
- Global vs. user-specific interest rates  

---

## 📈 Tokenomics (WIP)

- **Initial Global Interest Rate:** `5e10` (scaled by 1e18)
- **Global Rate Decreases Only**  
- **User Rate Locked** at time of deposit  
- **Interest accrues linearly** over time, per user

---

## 📡 Roadmap (in progress)

- [x] Vault + Token Core Contracts  
- [x] Rebase logic based on time & user-specific rates  
- [ ] Cross-chain bridging mechanism  
- [ ] Vault reward strategy (external yield integration)  
- [ ] Frontend dApp  
- [ ] Governance module

---

## 👷 Contributing

1. Fork the repo
2. Clone and install dependencies
3. Write or improve features/tests
4. Open a pull request

---

## 🧠 Notes

This project is a **work in progress** and will be extended over time with:
- Full Foundry test suite
- Frontend integration
- Bridging & yield mechanics
- DAO/Governance features
