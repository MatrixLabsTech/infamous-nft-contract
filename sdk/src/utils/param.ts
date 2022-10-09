export function stringToHex(text: string) {
  const encoder = new TextEncoder()
  const encoded = encoder.encode(text)
  return Array.from(encoded, (i) => i.toString(16).padStart(2, '0')).join('')
}

export function parseJson(text: string) {
  return JSON.parse(text)
}

export function paramToHex(value: string, type: string) {
  if (type === 'address') {
    return value.startsWith('0x') ? value.substring(2) : value
  } else if (type === '0x1::string::String') {
    return value
  } else if (type === 'u64') {
    return value
  } else if (type === 'vector<u8>') {
    return stringToHex(value)
  } else if (type === 'vector<vector<u8>>') {
    const arr = parseJson(value)
    return arr.map((a: any) => stringToHex(a as string))
  } else if (
    type === 'vector<bool>' ||
    type === 'vector<0x1::string::String>'
  ) {
    return parseJson(value)
  }
  return value
}
