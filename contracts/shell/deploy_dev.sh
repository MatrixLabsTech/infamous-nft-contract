#!/bin/bash

# BASEDIR=$(dirname "$0")
# WORKDIR=$(dirname "$BASEDIR")
# echo "$WORKDIR"

# cd "$WORKDIR"

# 1. remove old account
# rm -rf .aptos
# 2. init aptos account
# aptos init --assume-yes --rest-url https://fullnode.devnet.aptoslabs.com/v1 --faucet-url https://faucet.devnet.aptoslabs.com/
# 3. faucet
# aptos account fund-with-faucet --account default --amount 1000000000
# aptos account fund-with-faucet --account default --amount 1000000000
# 4. unit test contracts
aptos move test --named-addresses infamous=default
# 5. compile contractsz
aptos move compile --named-addresses infamous=default
# 6. deploy
echo "deploying..."
mkdir -p ./deployed-airtifact
aptos move publish --named-addresses infamous=default --assume-yes > deployed-airtifact/deployed.json
sed -i '1d' deployed-airtifact/deployed.json

echo "deployed success!!"
