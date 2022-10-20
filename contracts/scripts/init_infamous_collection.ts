import { AptosAccount, BCS, HexString } from 'aptos'
import {
  EntryFunction,
  TransactionPayloadEntryFunction,
} from 'aptos/dist/transaction_builder/aptos_types'

const moduleAddress =
  '0xd871bd97431e673709867a755aeed48c44a88510238385bd26eb2ccc12220160'

export const collectionConfig = {
  seed: '01',
  collection_name: 'infamousNFT',
  collection_uri:
    'https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png',
  per_max: 10,
  maximum: 100,
  description:
    'Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs',
  base_token_name: 'Infamous #',
  base_token_uri: 'https://beta.api.infamousnft.xyz/infamousnft/token/',
  default_property_keys: ['level', 'weapon'],
  default_property_values: ['0', ''],
  default_property_types: ['integer', 'string'],
}

async function main() {
  const privateKey =
    '0xa33eba7fcce71ed6a5ebc8bcf70ae356841e14b897f7718aa904b702bf2692ca'
  const operator = new AptosAccount(new HexString(privateKey).toUint8Array())
  console.log(
    `Use Operator: ${operator.address()} to initialize resource account and create collection.`
  )

  await initializeCollection(operator, seed)
  const afterResourceAddr = await getResourceAccountAddr(operator)
  console.log(`initializeResourceAccount addr: ${afterResourceAddr} `)
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

async function initializeCollection(account: AptosAccount, seed: string) {
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address().hex()}::infamous_nft`,
      'initialize_collection',
      [],
      [BCS.bcsSerializeStr(seed), BCS.bcsSerializeStr(auth_key)]
    )
  )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    client.getAccount(account.address()),
    client.getChainId(),
  ])

  const rawTxn = new TxnBuilderTypes.RawTransaction(
    TxnBuilderTypes.AccountAddress.fromHex(account.address()),
    BigInt(sequenceNumber),
    entryFunctionPayload,
    2000n,
    1n,
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(account, rawTxn)
  const pendingTxn = await client.submitSignedBCSTransaction(bcsTxn)
  await client.waitForTransaction(pendingTxn.hash)

  console.log('initialize success!') //ccc-log
}

interface IResourceAccount {
  type: string
  data?: {
    addr: string
    signer_cap: {
      account: string
    }
  }
}
export async function getResourceAccountAddr(
  operator: AptosAccount
): Promise<string> {
  try {
    const resourceAccount = await client.getAccountResource(
      operator.address(),
      `${operator.address().hex()}::dynamic_token::ResourceAccount`
    )

    const addr = (resourceAccount as IResourceAccount)?.data?.addr
    return addr
  } catch (e) {
    console.log(e) //ccc-log
    return ''
  }
}
