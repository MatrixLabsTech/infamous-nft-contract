import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'
import { client } from '../utils/base'

const NUMBER_MAX: number = 9007199254740991
const collection_name = "Alice's cat collection"
const token_name = "Alice's tabby"

async function main() {
  const privateKey =
    '0xddddd5f4f9ca6fbccdc138d2ec5d488878df042c65fcc55ca0fb1819be955caf'

  // const originAddress =
  //   '0xe556e1eefcf1a79782772b4b29a179f5aff32c21be8a1e42183caed7dae11747'

  // const privateKey =
  //   '0x5c8eae921b3737b26116f69aa358d425d6691aad957aea232d2281887cdf03c2'
  const originAddress =
    '0xa2bb12e530077a824e9c238506d8be0d881e5b42b1c5a8ac4041a1547cf64415'

  // 1. resolve aptos account
  const operator = new AptosAccount(
    new HexString(privateKey).toUint8Array()
    // address
  )
  console.log(`Use Operator: ${operator.address()}`)

  // 2.
  // await initResourceAccountScript(operator, "Alice's simple collection adddd")

  await createTokenByResourceAccount(
    operator,
    new HexString(
      '0x6899fbbe393685bce916c1aa0c511fb5f3a3c0fc159dbb0cab2cc5f87775e41b'
    ),
    new HexString(originAddress),
    collection_name,
    "Alice's simple collection",
    'https://aptos.dev'
  )

  // let token_balance = await getResourceAccount(operator.address())

  // console.log(`Operator's token balance: ${token_balance}`)
  // const token_data = await getTokenData(
  //   operator.address(),
  //   collection_name,
  //   token_name
  // )
  // console.log(`Operator's token data: ${JSON.stringify(token_data)}`)
}

if (require.main === module) {
  main().then((resp) => console.log(resp))
}

async function createTokenByResourceAccount(
  account: AptosAccount,
  resource_addr: HexString,
  origin_addr: HexString,
  name: string,
  description: string,
  uri: string
) {
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadScriptFunction(
      TxnBuilderTypes.ScriptFunction.natural(
        '0xe556e1eefcf1a79782772b4b29a179f5aff32c21be8a1e42183caed7dae11747::D1AptosToken',
        'create_collection_script',
        [],
        [
          resource_addr.toUint8Array(),
          origin_addr.toUint8Array(),
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
/** Creates a new collection within the specified account */
async function initResourceAccountScript(
  account: AptosAccount,
  seed: string,
  optional_auth_key = ''
) {
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadScriptFunction(
      TxnBuilderTypes.ScriptFunction.natural(
        '0xe556e1eefcf1a79782772b4b29a179f5aff32c21be8a1e42183caed7dae11747::D1AptosToken',
        'init_resource_account_script',
        [],
        [BCS.bcsSerializeStr(seed), BCS.bcsSerializeStr(optional_auth_key)]
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
  token_name: string,
  property_keys: Array<string> = [],
  property_values: Array<string> = [],
  property_types: Array<string> = []
) {
  // Serializes empty arrays
  const serializer = new BCS.Serializer()
  serializer.serializeU32AsUleb128(0)
  const scriptFunctionPayload =
    new TxnBuilderTypes.TransactionPayloadScriptFunction(
      TxnBuilderTypes.ScriptFunction.natural(
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
          serializer.getBytes(),
          serializer.getBytes(),
          serializer.getBytes(),
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

async function getResourceAccount(
  owner: HexString,
  creator: HexString,
  collection_name: string,
  token_name: string
): Promise<number> {
  const token_store = await client.getAccountResource(
    owner,
    '0xe556e1eefcf1a79782772b4b29a179f5aff32c21be8a1e42183caed7dae11747::proxyAptosToken'
  )

  const token_data_id = {
    creator: creator.hex(),
    collection: collection_name,
    name: token_name,
  }

  const token_id = {
    token_data_id,
    property_version: '0',
  }

  const token = await tableItem(
    (token_store.data as any)['tokens']['handle'],
    '0x3::token::TokenId',
    '0x3::token::Token',
    token_id
  )

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
