import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  TxnBuilderTypes,
} from 'aptos'
import { client } from './utils/base'

const { EntryFunction, TransactionPayloadEntryFunction, ChainId } =
  TxnBuilderTypes

async function main() {
  const privateKey =
    '0xa31b66a49f4279210bbd4f3b10cfd8fc555dca0e28e3be9946f6c057f9c1171f'

  const delegateAddr =
    '0x1a386d6601b56da763d40c327584cbde665b911291e408a6f60ca66af4098db0'

  const operator = new AptosAccount(new HexString(privateKey).toUint8Array())
  console.log(`delegate  ${operator.address()} to ${delegateAddr}`)

  const capabilityState = await getCapabilityState(operator)
  console.log(capabilityState) //ccc-log
  await delegate(operator, delegateAddr)
}

if (require.main === module) {
  main().then(() => process.exit(0))
}

async function delegate(account: AptosAccount, accountAddr: string) {
  const scriptFunctionPayload = new TransactionPayloadEntryFunction(
    EntryFunction.natural(
      `${account.address().hex()}::dynamic_token`,
      'delegate',
      [],
      [BCS.bcsToBytes(TxnBuilderTypes.AccountAddress.fromHex(accountAddr))]
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

interface ICapabilityState {
  type: string
  data?: {
    store: string[]
  }
}
export async function getCapabilityState(
  operator: AptosAccount
): Promise<string[]> {
  try {
    const capabilityState = await client.getAccountResource(
      operator.address(),
      `${operator.address().hex()}::dynamic_token::CapabilityState`
    )

    console.log(capabilityState) //ccc-log

    return (capabilityState as ICapabilityState)?.data?.store
  } catch (e) {
    return []
  }
}
