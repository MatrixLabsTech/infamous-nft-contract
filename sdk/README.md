# install

```
yarn add @white-matrix/infamous-contract-sdk
or
npm install @white-matrix/infamous-contract-sdk
```

# usage

```
  const client = new InfamousNFTClientImpl() // 'devnet' or 'testnet'
  const collectInfo = await client.collectionInfo()
  console.log(collectInfo) //ccc-log
  const tokenData = await client.tokenData('Infamous #1')
  console.log(tokenData) //ccc-log

  const owned = await client.tokenOwned(
    '0x90c1d4adb9668bb84aa16666abaf2870f6a7a0f05778e600ace09865994de948'
  )
  console.log(owned) //ccc-log

  const property = await client.tokenProperty('Infamous #1')
  console.log(property) //ccc-log

```
