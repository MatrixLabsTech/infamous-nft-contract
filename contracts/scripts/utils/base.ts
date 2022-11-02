import { AptosClient, FaucetClient, MaybeHexString } from 'aptos'

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
