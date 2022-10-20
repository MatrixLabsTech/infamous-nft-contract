## Infamous NFT Contract

Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs, This project contains all the contracts involved.

## ✨ Features

- dyanamic token properties
- token staking
- token binding
- flexible auth control
- shared resource account

## 📦 Packages

- contracts
  - sources
    - infamous_backend_auth.move
    - infamous_backend_open_box.move
    - infamous_backend_token_weapon_airdrop.move
    - infamous_common.move
    - infamous_manager_cap.move
    - infamous_nft.move
    - infamous_stake.move
    - infamous_upgrade_level.move
    - infamous_weapon_nft.move
    - infamous_weapon_status.move
    - infamous_weapon_wear.move

## 🔨 How to Use

### Step 1: Install the CLI

Install the precombiled binary for the Aptos CLI [install_cli](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli).

### Step 2: Install node dependence

change directory to the root of this project:

```
yarn
```

### Step 3: Create an account and fund it

1. change into `contracts` directory, begin to initialize a new local account:

```bash
cd contracts
yarn aptos-init
```

2. fund this account by running this command:

```bash
yarn faucet
```

---

### Step 4: Compile & Deploy contracts

- set the account used to compile&deploy contract
  open `contract`

```
yarn compile
yarn test
yarn aptos-move-publish
```

## 🔗 Links

[website](https://infamous-game-beta.whitematrix.workers.dev)

[github](https://github.com/MatrixLabsTech/infamous-nft-contract)
