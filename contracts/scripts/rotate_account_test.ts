import { AptosAccount, CoinClient, TxnBuilderTypes } from 'aptos'
import { client, faucetClient } from './utils/base'

async function main() {
  const coinClient = new CoinClient(client) // <:!:section_1a

  const alice = new AptosAccount()
  const bob = new AptosAccount()
  await faucetClient.fundAccount(alice.address(), 100_000_000)
  await faucetClient.fundAccount(bob.address(), 100_000)

  console.log('=== Initial Alice and Bob ===')
  console.log(`Alice:`)
  console.log(alice.toPrivateKeyObject())
  console.log(`Bob:`)
  console.log(bob.toPrivateKeyObject())
  console.log('')

  // Print out initial balances.
  console.log('=== Initial Balances ===')
  console.log(`Alice: ${await coinClient.checkBalance(alice)}`)
  console.log(`Bob: ${await coinClient.checkBalance(bob)}`)
  console.log('')

  const helperAccount = new AptosAccount()
  await faucetClient.fundAccount(helperAccount.address(), 0)
  console.log(`helperAccount Addr: ${helperAccount.address()}`)

  /// rotate peivate key
  const pendingTxn = await client.rotateAuthKeyEd25519(
    alice,
    helperAccount.signingKey.secretKey
  )
  await client.waitForTransaction(pendingTxn.hash)

  const rotatedAlice = new AptosAccount(
    helperAccount.signingKey.secretKey,
    alice.address()
  )

  const transHash = await coinClient.transfer(rotatedAlice, bob, 1_000, {
    gasUnitPrice: BigInt(100),
  })
  await client.waitForTransaction(transHash)

  console.log('=== After transfered, Rotated Balances ===')
  console.log(`RotatedAlice: ${await coinClient.checkBalance(rotatedAlice)}`)
  console.log(`Bob: ${await coinClient.checkBalance(bob)}`)
  console.log('')
}

if (require.main === module) {
  main().then(() => process.exit(0))
}
