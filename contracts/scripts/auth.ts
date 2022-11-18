import {
  AptosAccount,
  HexString,
  TxnBuilderTypes,
  BCS,
  AptosClient,
} from 'aptos'
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
      `${account.address}::infamous_backend_auth`,
      'delegate',
      [],
      [
        BCS.bcsToBytes(
          AccountAddress.fromHex(
            '0x523b8b8eae6ada0e4af325518c014dbbf8a6ad6404cc4c5583a3b6115e491974'
          )
        ),
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
