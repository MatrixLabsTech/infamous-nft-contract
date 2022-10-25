import {
  AptosAccount,
  CoinClient,
  HexString,
  TxnBuilderTypes,
  BCS,
} from 'aptos'
import { client, faucetClient } from './utils/base'

async function main() {
  const coinClient = new CoinClient(client)

  // init account alice for rotate, bob for receive apt, helperAccount for rotate
  const alice = new AptosAccount()
  const bob = new AptosAccount()
  const helperAccount = new AptosAccount()
  await faucetClient.fundAccount(alice.address(), 100_000_000)
  await faucetClient.fundAccount(bob.address(), 100_000)
  await faucetClient.fundAccount(helperAccount.address(), 0)

  console.log('=== Initial Alice and Bob ===')
  console.log(`Alice:`)
  console.log(alice.toPrivateKeyObject())
  console.log(`Bob:`)
  console.log(bob.toPrivateKeyObject())
  console.log(`HelperAccount:`)
  console.log(helperAccount.toPrivateKeyObject())
  console.log('')

  console.log('=== Initial Balances ===')
  console.log(`Alice: ${await coinClient.checkBalance(alice)}`)
  console.log(`Bob: ${await coinClient.checkBalance(bob)}`)
  console.log('')

  /// rotate peivate key
  const pendingTxn = await client.rotateAuthKeyEd25519(
    alice,
    helperAccount.signingKey.secretKey
  )
  await client.waitForTransaction(pendingTxn.hash)

  const origAddressHex = await client.lookupOriginalAddress(
    helperAccount.address()
  )

  const origAddress = TxnBuilderTypes.AccountAddress.fromHex(origAddressHex)
  const originAddressString = HexString.fromUint8Array(
    BCS.bcsToBytes(origAddress)
  ).hex()

  console.log('')
  console.log(`RotatedAlice: ${originAddressString}`)
  console.log('')

  const rotatedAlice = new AptosAccount(
    helperAccount.signingKey.secretKey,
    originAddressString
  )

  // use rotated account to transfer
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
