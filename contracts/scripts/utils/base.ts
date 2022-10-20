import {
  AptosAccount,
  AptosClient,
  FaucetClient,
  HexString,
  MaybeHexString,
  TxnBuilderTypes,
} from 'aptos'

export const NODE_URL = 'https://fullnode.devnet.aptoslabs.com'
export const FAUCET_URL = 'https://faucet.devnet.aptoslabs.com'

export const client = new AptosClient(NODE_URL)
export const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL)

export async function accountBalance(
  accountAddress: MaybeHexString
): Promise<number | null> {
  const resource = await client.getAccountResource(
    accountAddress,
    '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>'
  )
  if (resource == null) {
    return null
  }

  return parseInt((resource.data as any)['coin']['value'])
}

/** Publish a new module to the blockchain within the specified account */
export async function publishModule(
  accountFrom: AptosAccount,
  moduleHex: string
): Promise<string> {
  const moduleBundlePayload =
    new TxnBuilderTypes.TransactionPayloadModuleBundle(
      new TxnBuilderTypes.ModuleBundle([
        new TxnBuilderTypes.Module(new HexString(moduleHex).toUint8Array()),
      ])
    )

  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    client.getAccount(accountFrom.address()),
    client.getChainId(),
  ])

  const rawTxn = new TxnBuilderTypes.RawTransaction(
    TxnBuilderTypes.AccountAddress.fromHex(accountFrom.address()),
    BigInt(sequenceNumber),
    moduleBundlePayload,
    1000n,
    1n,
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new TxnBuilderTypes.ChainId(chainId)
  )

  const bcsTxn = AptosClient.generateBCSTransaction(accountFrom, rawTxn)
  const transactionRes = await client.submitSignedBCSTransaction(bcsTxn)

  return transactionRes.hash
}

export function output(type: 'error' | 'success' | 'info', message: string) {
  switch (type) {
    case 'error': {
      console.log('\x1b[31m%s\x1b[0m', `Error: ${message}`)
      return
    }
    case 'success': {
      console.log('\x1b[32m%s\x1b[0m', `Success: ${message}`)
      return
    }
    default: {
      console.log(message)
      return
    }
  }
}
