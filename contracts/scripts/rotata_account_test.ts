import { AptosAccount, TxnBuilderTypes } from 'aptos'
import { client, faucetClient } from './utils/base'

async function main() {
  const alice = new AptosAccount()
  await faucetClient.fundAccount(alice.address(), 100_000_000)

  const helperAccount = new AptosAccount()

  const pendingTxn = await client.rotateAuthKeyEd25519(
    alice,
    helperAccount.signingKey.secretKey
  )

  await client.waitForTransaction(pendingTxn.hash)

  const origAddressHex = await client.lookupOriginalAddress(
    helperAccount.address()
  )
  // Sometimes the returned addresses do not have leading 0s. To be safe, converting hex addresses to AccountAddress
  const origAddress = TxnBuilderTypes.AccountAddress.fromHex(origAddressHex)
  const aliceAddress = TxnBuilderTypes.AccountAddress.fromHex(alice.address())

  console.log({ origAddress })
  console.log({ aliceAddress })
}

if (require.main === module) {
  main().then(() => process.exit(0))
}
