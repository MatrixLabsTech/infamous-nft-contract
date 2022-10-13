import { deployment } from '@white-matrix/infamous-contract-sdk'
import { AptosClient } from 'aptos'

export const client = new AptosClient('https://fullnode.devnet.aptoslabs.com')
export const moduleAddress = deployment.devnet.moduleAddress
export const infamousNft = deployment.devnet.infamousNft
export const infamousStake = deployment.devnet.infamousStake
export const infamousManagerCap = deployment.devnet.infamousManagerCap
export const infamousUpgradeLevel = deployment.devnet.infamousUpgradeLevel
export const infamousBackendOpenBox = deployment.devnet.infamousBackendOpenBox
export const infamousBackendAuth = deployment.devnet.infamousBackendAuth
export const infamousWeaponNft = deployment.devnet.infamousWeaponNft

export const metadataModuleName = 'metadata'
export const tokenModuleName = 'token'
