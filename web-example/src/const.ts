import { deployment } from '@white-matrix/infamous-contract-sdk'
import { AptosClient } from 'aptos'

export const client = new AptosClient('https://fullnode.devnet.aptoslabs.com')
export const moduleAddress = deployment.devnet.moduleAddress
export const dynamicTokenModuleName = deployment.devnet.nftModuleName
export const dynamicManagerModuleName = deployment.devnet.managerCapModuleName

export const metadataModuleName = 'metadata'
export const tokenModuleName = 'token'
