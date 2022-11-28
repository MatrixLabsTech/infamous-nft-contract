import {
  AptosAccount,
  HexString,
  TxnBuilderTypes,
  BCS,
  AptosClient,
} from 'aptos'
import { getPropertyMap } from './get_properties'
import { client, testnetClient } from './utils/base'
import { getConfigAccount } from './utils/config'

const {
  AccountAddress,
  EntryFunction,
  TransactionPayloadEntryFunction,
  RawTransaction,
  ChainId,
} = TxnBuilderTypes
async function main() {
  const env = process.argv[2]
  let realClient = client
  if (env === 'testnet') {
    realClient = testnetClient
  }
  const defaultPrivateKey = await getConfigAccount()
  const deployer = new AptosAccount(
    new HexString(defaultPrivateKey).toUint8Array()
  )
  const account = deployer.toPrivateKeyObject()
  console.log('=== Use Account ===')
  console.log(account)
  const gender = 'female'
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address}::infamous_backend_open_box`,
      'open_box',
      [],
      [
        BCS.bcsSerializeStr('Infamous #5'),
        BCS.bcsSerializeStr(randomProperty(gender, 'background')),
        BCS.bcsSerializeStr(randomProperty(gender, 'clothing')),
        BCS.bcsSerializeStr(randomProperty(gender, 'earrings')),
        BCS.bcsSerializeStr(randomProperty(gender, 'eyebrows')),
        BCS.bcsSerializeStr(randomProperty(gender, 'face-accessory')),
        BCS.bcsSerializeStr(randomProperty(gender, 'eyes')),
        BCS.bcsSerializeStr(randomProperty(gender, 'hair')),
        BCS.bcsSerializeStr(randomProperty(gender, 'mouth')),
        BCS.bcsSerializeStr(randomProperty(gender, 'neck')),
        BCS.bcsSerializeStr(randomProperty(gender, 'tattoo')),
        BCS.bcsSerializeStr(gender),
        BCS.bcsSerializeStr(randomProperty(gender, 'weapon')),
        BCS.bcsSerializeStr('Lv 1'),
        BCS.bcsSerializeStr('bronze'),
        BCS.bcsSerializeStr('30'),
      ]
    )
  )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    realClient.getAccount(deployer.address()),
    realClient.getChainId(),
  ])

  const rawTxn = new RawTransaction(
    // Transaction sender account address
    AccountAddress.fromHex(deployer.address()),
    BigInt(sequenceNumber),
    entryFunctionPayload,
    // Max gas unit to spend
    BigInt(500000),
    // Gas price per unit
    BigInt(100),
    // Expiration timestamp. Transaction is discarded if it is not executed within 10 seconds from now.
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new ChainId(chainId)
  )

  // Sign the raw transaction with account1's private key
  const bcsTxn = AptosClient.generateBCSTransaction(deployer, rawTxn)

  const transactionRes = await realClient.submitSignedBCSTransaction(bcsTxn)

  console.log({ hash: transactionRes.hash })

  await realClient.waitForTransaction(transactionRes.hash)
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

export function randomProperty(gender: string, property: string) {
  const map = getPropertyMap()
  const propertyMap = map[gender]
  if (!propertyMap) {
    throw new Error('gender not support.')
  }
  const pMap = propertyMap[property]
  if (!pMap) {
    throw new Error('property not support.')
  }
  const keys = Object.keys(pMap)
  const randomIndex = Math.floor(Math.random() * keys.length)
  return keys[randomIndex]
}
