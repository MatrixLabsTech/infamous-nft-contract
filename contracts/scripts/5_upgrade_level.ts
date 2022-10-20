import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'
import { client } from './utils/base'
import { collection_name } from './nft/nft_constants'

const { EntryFunction, ChainId } = TxnBuilderTypes

const token_name = "Mimi's tabby"

const resourceAddr =
  '0xb3733d5eb422d70f58ba6a07b6c614bc90b2fd7455e97c749db41eaafdbd5c2c'

async function main() {
  const privateKey =
    '0xa31b66a49f4279210bbd4f3b10cfd8fc555dca0e28e3be9946f6c057f9c1171f'

  const operator = new AptosAccount(new HexString(privateKey).toUint8Array())
  console.log(`use operator  ${operator.address()} to update token property`)

  await updateLevelScript(operator, collection_name, token_name, 1, 50)
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

async function updateLevelScript(
  account: AptosAccount,
  collection_name: string,
  name: string,
  supply: number | bigint,
  level: number
) {
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadEntryFunction(
      EntryFunction.natural(
        `${account.address().hex()}::metadata`,
        'upgrade_level',
        [],
        [
          BCS.bcsToBytes(
            TxnBuilderTypes.AccountAddress.fromHex(account.address())
          ),
          BCS.bcsToBytes(TxnBuilderTypes.AccountAddress.fromHex(resourceAddr)),
          BCS.bcsToBytes(TxnBuilderTypes.AccountAddress.fromHex(resourceAddr)),
          BCS.bcsSerializeStr(collection_name),
          BCS.bcsSerializeStr(name),
          BCS.bcsSerializeUint64(0),
          BCS.bcsSerializeUint64(supply),
          BCS.bcsSerializeUint64(level),
        ]
      )
    )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    client.getAccount(account.address()),
    client.getChainId(),
  ])

  const rawTxn = new TxnBuilderTypes.RawTransaction(
    TxnBuilderTypes.AccountAddress.fromHex(account.address()),
    BigInt(sequenceNumber),
    scriptFunctionPayload,
    1000n,
    1n,
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(account, rawTxn)
  const pendingTxn = await client.submitSignedBCSTransaction(bcsTxn)
  await client.waitForTransaction(pendingTxn.hash)
}
