import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'
import { client } from './utils/base'
import {
  collection_name,
  description,
  collection_uri,
} from './nft/nft_constants'

const { EntryFunction, ChainId } = TxnBuilderTypes

const NUMBER_MAX: number = 9007199254740991
const token_name = "Mimi's tabby"

async function main() {
  const privateKey =
    '0xa31b66a49f4279210bbd4f3b10cfd8fc555dca0e28e3be9946f6c057f9c1171f'

  const operator = new AptosAccount(new HexString(privateKey).toUint8Array())
  console.log(`use operator  ${operator.address()} to create token script`)

  await createTokenScript(
    operator,
    collection_name,
    token_name,
    "Mimi's tabby",
    1,
    'https://aptos.dev/img/nyan.jpeg',
    10
  )
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

async function createTokenScript(
  account: AptosAccount,
  collection_name: string,
  name: string,
  description: string,
  supply: number | bigint,
  uri: string,
  level: number
) {
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadEntryFunction(
      EntryFunction.natural(
        `${account.address().hex()}::metadata`,
        'create_token_script',
        [],
        [
          BCS.bcsToBytes(
            TxnBuilderTypes.AccountAddress.fromHex(account.address())
          ),
          BCS.bcsSerializeStr(collection_name),
          BCS.bcsSerializeStr(name),
          BCS.bcsSerializeStr(description),
          BCS.bcsSerializeUint64(supply),
          BCS.bcsSerializeUint64(NUMBER_MAX),
          BCS.bcsSerializeStr(uri),
          BCS.bcsToBytes(
            TxnBuilderTypes.AccountAddress.fromHex(account.address())
          ),
          BCS.bcsSerializeUint64(0),
          BCS.bcsSerializeUint64(0),
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
