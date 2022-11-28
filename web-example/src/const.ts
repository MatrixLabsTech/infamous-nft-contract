import { deployment } from '@white-matrix/infamous-contract-sdk'
import { AptosNetwork } from '@white-matrix/infamous-contract-sdk/dist/InfamousNFTClientImpl'
import { AptosClient } from 'aptos'

export const testClient = new AptosClient(
  'https://fullnode.testnet.aptoslabs.com'
)
export const devClient = new AptosClient(
  'https://fullnode.devnet.aptoslabs.com'
)
export const moduleAddress = deployment.testnet.moduleAddress
export const infamousNft = deployment.testnet.infamousNft
export const infamousLock = deployment.testnet.infamousLock
export const infamousManagerCap = deployment.testnet.infamousManagerCap
export const infamousUpgradeLevel = deployment.testnet.infamousUpgradeLevel
export const infamousBackendOpenBox = deployment.testnet.infamousBackendOpenBox
export const infamousBackendAuth = deployment.testnet.infamousBackendAuth
export const infamousWeaponNft = deployment.testnet.infamousWeaponNft
export const infamousWeaponWear = deployment.testnet.infamousWeaponWear

export function getClient(network: AptosNetwork) {
  if (network === AptosNetwork.Devnet) {
    return devClient
  } else {
    return testClient
  }
}

export const metadataModuleName = 'metadata'
export const tokenModuleName = 'token'
