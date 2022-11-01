import fs from 'fs'
import path from 'path'
export async function getAbiHexArray(): Promise<string[]> {
  const compiled = fs
    .readFileSync(
      path.resolve(__dirname, '../../deployed-airtifact/compiled.json')
    )
    .toString()

  const abiMap = JSON.parse(compiled)

  return Object.keys(abiMap).map((file) => abiMap[file])
}
