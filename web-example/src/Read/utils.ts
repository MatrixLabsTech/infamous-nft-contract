import { AptosNetwork } from '@white-matrix/infamous-contract-sdk/dist/InfamousNFTClientImpl'
import { getClient } from '../const'

export async function tableItem(
  network: AptosNetwork,
  handle: string,
  keyType: string,
  valueType: string,
  key: any
): Promise<any> {
  const getTokenTableItemRequest = {
    key_type: keyType,
    value_type: valueType,
    key,
  }
  return getClient(network).getTableItem(handle, getTokenTableItemRequest)
}
