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
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address}::infamous_backend_token_weapon_airdrop_box`,
      'airdrop_level_five',
      [],
      [
        BCS.bcsSerializeStr('Infamous #23'),
        BCS.bcsToBytes(
          AccountAddress.fromHex(
            '0x1a0286514bf9433294a0b5b13d8cc6c27d60948e4163fed406ae3aca5c539802'
          )
        ),
        BCS.bcsSerializeStr('LV5'),
      ]
    )
  )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    client.getAccount(deployer.address()),
    client.getChainId(),
  ])

  const rawTxn = new RawTransaction(
    AccountAddress.fromHex(deployer.address()),
    BigInt(sequenceNumber),
    entryFunctionPayload,
    BigInt(500000),
    BigInt(100),
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new ChainId(chainId)
  )
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
