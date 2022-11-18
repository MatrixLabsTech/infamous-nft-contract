import fs from 'fs'
import path from 'path'
export async function getConfigAccount() {
  const accountConfig = fs
    .readFileSync(path.resolve(__dirname, '../../.aptos/config.yaml'))
    .toString()

  const defaultPrivateKey = /private_key: '(.*)'/g.exec(accountConfig)[1]

  if (!defaultPrivateKey) {
    throw new Error('Account Config not found in .aptos')
  }

  return defaultPrivateKey
}
