# aptos develop boilerplate

## Step 1: Install the CLI

[Install the precombiled binary for the Aptos CLI][install_cli].

## Step 2: Install node dependence

change directory to the root of this project:

```
yarn
```

---

## Step 3: Create an account and fund it

- change into `contract` directory

```
cd contract
```

After installing the CLI binary, next step is to create and fund an account on the Aptos blockchain.

1. Begin by starting a new terminal and run the below command to initialize a new local account:

```bash
aptos init
```

The output will be similar to below.

```text
Enter your rest endpoint [Current: None | No input: https://fullnode.devnet.aptoslabs.com/v1]

No rest url given, using https://fullnode.devnet.aptoslabs.com/v1...
Enter your faucet endpoint [Current: None | No input: https://faucet.devnet.aptoslabs.com | 'skip' to not use a faucet]

No faucet url given, using https://faucet.devnet.aptoslabs.com...
Enter your private key as a hex literal (0x...) [Current: None | No input: Generate new key (or keep one if present)]

No key given, generating key...
Account a345dbfb0c94416589721360f207dcc92ecfe4f06d8ddc1c286f569d59721e5a doesn't exist, creating it and funding it with 10000 coins
Aptos is now set up for account a345dbfb0c94416589721360f207dcc92ecfe4f06d8ddc1c286f569d59721e5a!  Run `aptos help` for more information about commands
{
  "Result": "Success"
}
```

The account address in the above output: `a345dbfb0c94416589721360f207dcc92ecfe4f06d8ddc1c286f569d59721e5a` is your new account, and is aliased as the profile `default`. This account address will be different for you as it is generated randomly. From now on, either `default` or `0xa345dbfb0c94416589721360f207dcc92ecfe4f06d8ddc1c286f569d59721e5a` are interchangeable.

2. Now fund this account by running this command:

```bash
aptos account fund-with-faucet --account default
```

You will see an output similar to the below:

```
{
  "Result": "Added 10000 coins to account a345dbfb0c94416589721360f207dcc92ecfe4f06d8ddc1c286f569d59721e5a"
}
```

---

## Step 4: Compile & Deploy contracts

- set the account used to compile&deploy contract
  open `contract`

```
yarn compile
yarn test
yarn aptos-move-publish
```

## 3. build sdk for web develop

## 4. use sdk in dapp
