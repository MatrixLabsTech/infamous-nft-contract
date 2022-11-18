import {
  AptosAccount,
  HexString,
  TxnBuilderTypes,
  BCS,
  AptosClient,
} from 'aptos'
import { resolveUrlEncodeMap } from './get_properties'
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

  const { properties, properties_values } = resolveUrlEncodeMap()
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address}::infamous_properties_url_encode_map`,
      'set_property_map',
      [],
      [
        BCS.serializeVectorWithFunc(properties, 'serializeStr'),
        BCS.serializeVectorWithFunc(properties_values, 'serializeStr'),
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
