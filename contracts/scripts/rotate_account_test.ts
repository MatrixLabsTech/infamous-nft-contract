import { AptosAccount, CoinClient, TxnBuilderTypes } from 'aptos'
import { client, faucetClient } from './utils/base'

async function main() {
  const coinClient = new CoinClient(client) // <:!:section_1a

  const alice = new AptosAccount()
  const bob = new AptosAccount()
  await faucetClient.fundAccount(alice.address(), 100_000_000)
  await faucetClient.fundAccount(bob.address(), 100)

  // transfer

  // Print out initial balances.
  console.log('=== Initial Balances ===')
  // :!:>section_4
  console.log(`Alice Addr: ${alice.address()}`)
  console.log(`Alice: ${await coinClient.checkBalance(alice)}`)
  console.log('')

  const helperAccount = new AptosAccount()
  await faucetClient.fundAccount(helperAccount.address(), 0) // <:!:section_3
  console.log(`helperAccount Addr: ${helperAccount.address()}`)

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

  // Print out initial balances.
  console.log('=== Initial Balances ===')
  // :!:>section_4
  console.log(`helperAccount origAddress: ${origAddress}`)
  console.log(`helperAccount: ${await coinClient.checkBalance(helperAccount)}`)
  console.log('')

  // const transHash = await coinClient.transfer(alice, bob, 1_000, {
  //   gasUnitPrice: BigInt(100),
  // })
  // await client.waitForTransaction(transHash)

  console.log({ origAddress })
  console.log({ aliceAddress })
}

if (require.main === module) {
  main().then(() => process.exit(0))
}
