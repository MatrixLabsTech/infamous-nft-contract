import { client } from '../const'

export async function tableItem(
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
  return client.getTableItem(handle, getTokenTableItemRequest)
}
