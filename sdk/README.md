# install

```
yarn add @white-matrix/infamous-contract-sdk
or
npm install @white-matrix/infamous-contract-sdk
```

# usage

```
const client = new InfamousNFTClientImpl('devnet')
    const collectInfo = await client.collectionInfo()
    console.log({ collectInfo }) //ccc-log

    const coll = await client.tokenClient.getCollectionData(
      '0x307bd9d1be75ccd2f7670c5b7564b0cd26b41c1841b455ea6a0ea9eda0e0266f',
      "Alice's"
    )
    console.log({ coll })

    const tokenOwned = await client.tokenOwned(
      '0xc0db5b48fd82d6aaa00bac2570e22e6faccd0e8561b8d0813307b76cb354096f'
    )
    console.log(tokenOwned) //ccc-log

```
