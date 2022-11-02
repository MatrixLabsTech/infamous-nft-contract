
#!/bin/bash
# 2. unit test contracts
aptos move test --named-addresses infamous=default
# 3. compile contractsz
aptos move compile --named-addresses infamous=default
# 4. deploy
aptos move publish --named-addresses infamous=default --assume-yes > deployed.txt
# 5. generate an deployed file

echo "upgrade success!!"
