import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'

import { client } from './utils/base'

const {
  AccountAddress,
  TypeTagStruct,
  EntryFunction,
  StructTag,
  TransactionPayloadEntryFunction,
  RawTransaction,
  ChainId,
} = TxnBuilderTypes

async function main() {
  const privateKey =
    '0xa31b66a49f4279210bbd4f3b10cfd8fc555dca0e28e3be9946f6c057f9c1171f'
  const operator = new AptosAccount(new HexString(privateKey).toUint8Array())
  console.log(
    `Use Operator: ${operator.address()} to initialize resource account.`
  )

  const seed = 'random seed'
  const resourceAddr = await getResourceAccountAddr(operator)
  if (resourceAddr) {
    console.log(`resource account exist addr: ${resourceAddr} `)
    return
  }

  await initializeResourceAccount(operator, seed)
  const afterResourceAddr = await getResourceAccountAddr(operator)
  console.log(`initializeResourceAccount addr: ${afterResourceAddr} `)
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

async function initializeResourceAccount(
  account: AptosAccount,
  seed: string,
  auth_key: string = ''
) {
  const entryFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address().hex()}::dynamic_token`,
      'initialize_resource_account',
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
