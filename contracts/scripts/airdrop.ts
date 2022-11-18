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
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address}::infamous_backend_token_weapon_airdrop_box`,
      'airdrop_level_five',
      [],
      [
        BCS.bcsSerializeStr('Infamous #23'),
        BCS.bcsToBytes(
          AccountAddress.fromHex(
            '0x081b61647e533b9fe2267e61c354746e37990dd0112947b9975e8d94509a7614'
          )
        ),
        BCS.bcsSerializeStr('Lv 5'),
      ]
    )
  )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    realClient.getAccount(deployer.address()),
    realClient.getChainId(),
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
