import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'
import { EntryFunction } from 'aptos/dist/transaction_builder/aptos_types'
import { client } from '../utils/base'

const NUMBER_MAX: number = 9007199254740991
const collection_name = "Mimi's cat collection"
const token_name = "Mimi's tabby"

async function main() {
  // 1. resolve aptos account
  const operator = new AptosAccount(
    new HexString(
      '0x70b563276e660a7bf1fd397dba460a40d6af00c6b274b52e20ac845a6f847a92'
    ).toUint8Array()
  )
  console.log(`Use Operator: ${operator.address()}`)

  // 2.
  await createCollection(
    operator,
    collection_name,
    "Mimi's simple collection",
    'https://aptos.dev'
  )

  // await createToken(
  //   operator,
  //   collection_name,
  //   token_name,
  //   "Mimi's tabby",
  //   1,
  //   'https://aptos.dev/img/nyan.jpeg',
  //   ['size'],
  //   ['1'],
  //   ['integer']
  // )

  let token_balance = await getTokenBalance(
    operator.address(),
    operator.address(),
    collection_name,
    token_name
  )

  console.log(`Operator's token balance: ${token_balance}`)

  // await mutateTokenProperties(
  //   operator,
  //   collection_name,
  //   token_name,
  //   ['size'],
  //   ['888'],
  //   ['integer']
  // )
  // console.log(`MUTATE DONE`)

  const token_data = await getTokenData(
    operator.address(),
    collection_name,
    token_name
  )
  console.log(`Operator's token data: ${JSON.stringify(token_data)}`)
}

if (require.main === module) {
  main().then((resp) => console.log(resp))
}

/** Creates a new collection within the specified account */
async function createCollection(
  account: AptosAccount,
  name: string,
  description: string,
  uri: string
) {
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadEntryFunction(
      EntryFunction.natural(
        '0x3::token',
        'create_collection_script',
        [],
        [
          BCS.bcsSerializeStr(name),
          BCS.bcsSerializeStr(description),
          BCS.bcsSerializeStr(uri),
          BCS.bcsSerializeUint64(NUMBER_MAX),
          serializeVectorBool([false, true, false]), // change the url
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
    new TxnBuilderTypes.ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(account, rawTxn)
  const pendingTxn = await client.submitSignedBCSTransaction(bcsTxn)
  await client.waitForTransaction(pendingTxn.hash)
}

function serializeVectorBool(vecBool: boolean[]) {
  const serializer = new BCS.Serializer()
  serializer.serializeU32AsUleb128(vecBool.length)
  vecBool.forEach((el) => {
    serializer.serializeBool(el)
  })
  return serializer.getBytes()
}

function serializeVectorString(vecString: string[]) {
  const serializer = new BCS.Serializer()
  serializer.serializeU32AsUleb128(vecString.length)
  vecString.forEach((el) => {
    serializer.serializeStr(el)
  })
  return serializer.getBytes()
}

async function createToken(
  account: AptosAccount,
  collection_name: string,
  name: string,
  description: string,
  supply: number | bigint,
  uri: string,
  property_keys: Array<string> = [],
  property_values: Array<string> = [],
  property_types: Array<string> = []
) {
  // Serializes empty arrays
  const serializer = new BCS.Serializer()
  serializer.serializeU32AsUleb128(0)

  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadEntryFunction(
      EntryFunction.natural(
        '0x3::token',
        'create_token_script',
        [],
        [
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
          serializeVectorBool([false, false, false, false, true]), // change property
          serializeVectorString(property_keys),
          serializeVectorString(property_values),
          serializeVectorString(property_types),
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
    new TxnBuilderTypes.ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(account, rawTxn)
  const pendingTxn = await client.submitSignedBCSTransaction(bcsTxn)
  await client.waitForTransaction(pendingTxn.hash)
}
// mutate_token_properties
async function mutateTokenProperties(
  account: AptosAccount,
  collection_name: string,
  token_name: string,
  property_keys: Array<string> = [],
  property_values: Array<string> = [],
  property_types: Array<string> = []
) {
  // Serializes empty arrays
  const serializer = new BCS.Serializer()
  serializer.serializeU32AsUleb128(0)
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadEntryFunction(
      EntryFunction.natural(
        '0x3::token',
        'mutate_token_properties',
        [],
        [
          BCS.bcsToBytes(
            TxnBuilderTypes.AccountAddress.fromHex(account.address())
          ),
          BCS.bcsToBytes(
            TxnBuilderTypes.AccountAddress.fromHex(account.address())
          ),
          BCS.bcsSerializeStr(collection_name),
          BCS.bcsSerializeStr(token_name),
          BCS.bcsSerializeUint64(1),
          BCS.bcsSerializeUint64(1),
          serializeVectorString(property_keys),
          serializeVectorString(property_values),
          serializeVectorString(property_types),
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
    new TxnBuilderTypes.ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(account, rawTxn)
  const pendingTxn = await client.submitSignedBCSTransaction(bcsTxn)
  await client.waitForTransaction(pendingTxn.hash)
}

async function tableItem(
  handle: string,
  keyType: string,
  valueType: string,
  key: any
): Promise<any> {
  const getTokenTableItemRequest = {
    key_type: keyType,
    value_type: valueType,
    key,
  }
  return client.getTableItem(handle, getTokenTableItemRequest)
}

async function getTokenBalance(
  owner: HexString,
  creator: HexString,
  collection_name: string,
  token_name: string
): Promise<number> {
  const token_store = await client.getAccountResource(
    owner,
    '0x3::token::TokenStore'
  )

  const token_data_id = {
    creator: creator.hex(),
    collection: collection_name,
    name: token_name,
  }

  const token_id = {
    token_data_id,
    property_version: '1',
  }

  const token = await tableItem(
    (token_store.data as any)['tokens']['handle'],
    '0x3::token::TokenId',
    '0x3::token::Token',
    token_id
  )

  console.log(JSON.stringify(token.data)) //ccc-log

  return token.data.amount
}

async function getTokenData(
  creator: HexString,
  collection_name: string,
  token_name: string
): Promise<any> {
  const collections = await client.getAccountResource(
    creator,
    '0x3::token::Collections'
  )

  const token_data_id = {
    creator: creator.hex(),
    collection: collection_name,
    name: token_name,
  }

  const token = await tableItem(
    (collections.data as any)['token_data']['handle'],
    '0x3::token::TokenDataId',
    '0x3::token::TokenData',
    token_data_id
  )
  return token.data
}
