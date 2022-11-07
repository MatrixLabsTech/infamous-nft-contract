import {
  AptosAccount,
  HexString,
  TxnBuilderTypes,
  BCS,
  AptosClient,
} from 'aptos'
import { getPropertyMap } from './get_properties'
import { client } from './utils/base'
import { getConfigAccount } from './utils/config'

const {
  AccountAddress,
  EntryFunction,
  TransactionPayloadEntryFunction,
  RawTransaction,
  ChainId,
} = TxnBuilderTypes
async function main() {
  const defaultPrivateKey = await getConfigAccount()
  const deployer = new AptosAccount(
    new HexString(defaultPrivateKey).toUint8Array()
  )
  const account = deployer.toPrivateKeyObject()
  console.log('=== Use Account ===')
  console.log(account)
  const gender = 'male'
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address}::infamous_backend_token_weapon_airdrop`,
      'airdrop_level_five',
      [],
      [
        BCS.bcsSerializeStr('Infamous #15'),
        BCS.bcsToBytes(
          AccountAddress.fromHex(
            '0x4e1bd8fa766c0eada557bf8b456c59c0d9bf2e6e1a0635b78192d3e06c3c1dfe'
          )
        ),
        // BCS.bcsSerializeStr(randomProperty(gender, 'weapon')),
        BCS.bcsSerializeStr('warglaive of azzinoth'),
        BCS.bcsSerializeStr('1'),
        BCS.bcsSerializeStr('gold'),
        BCS.bcsSerializeStr('gold'),
      ]
    )
  )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    client.getAccount(deployer.address()),
    client.getChainId(),
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

  const transactionRes = await client.submitSignedBCSTransaction(bcsTxn)

  console.log({ hash: transactionRes.hash })

  await client.waitForTransaction(transactionRes.hash)
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
