import {
  AptosAccount,
  CoinClient,
  HexString,
  TxnBuilderTypes,
  BCS,
  TransactionBuilderABI,
  AptosClient,
} from 'aptos'
import { client, faucetClient } from './utils/base'
import fs from 'fs'
import path from 'path'

interface IMap {
  [key: string]: {
    [key: string]: {
      [key: string]: string
    }
  }
}
const {
  AccountAddress,
  TypeTagStruct,
  EntryFunction,
  StructTag,
  TransactionPayloadEntryFunction,
  RawTransaction,
  ChainId,
} = TxnBuilderTypes
async function main() {
  //   const coinClient = new CoinClient(client)
  //   // init account alice for rotate, bob for receive apt, helperAccount for rotate
  //   const alice = new AptosAccount()
  //   const bob = new AptosAccount()
  //   const helperAccount = new AptosAccount()
  //   await faucetClient.fundAccount(alice.address(), 100_000_000)

  const deployer = new AptosAccount(
    new HexString(
      '0x23cf0a93495baab7d59a97ba75ab8db7124fd55fe7ed9bbe60d6ba38d53eaa1d'
    ).toUint8Array()
  )
  const account = deployer.toPrivateKeyObject()
  console.log('=== Use Account ===')
  console.log(account)

  const { properties, properties_values } = resolveUrlEncodeMap()

  console.log(JSON.stringify(properties))
  console.log(JSON.stringify(properties_values))
}

function resolveUrlEncodeMap() {
  const properties: string[] = []
  const properties_values: string[] = []

  properties.push('femalegenderfemale')
  properties_values.push('0')
  properties.push('malegendermale')
  properties_values.push('1')

  const mapString = fs
    .readFileSync(path.resolve(__dirname, './properties.json'))
    .toString()
  const map = JSON.parse(mapString) as IMap

  // resolve male
  Object.keys(map.male).forEach((valueKey: string) => {
    const valueMap = map.male[valueKey]
    Object.keys(valueMap).forEach((value: string) => {
      const encode = valueMap[value]
      properties.push(`male${valueKey}${value}`)
      properties_values.push(encode)
    })
  })
  // resolve female
  Object.keys(map.female).forEach((valueKey: string) => {
    const valueMap = map.male[valueKey]
    Object.keys(valueMap).forEach((value: string) => {
      const encode = valueMap[value]
      properties.push(`female${valueKey}${value}`)
      properties_values.push(encode)
    })
  })

  return { properties, properties_values }
}

if (require.main === module) {
  main().then(() => process.exit(0))
}
