import fs from 'fs'
import path from 'path'

export interface IMap {
  [key: string]: {
    [key: string]: {
      [key: string]: string
    }
  }
}

export function getPropertyMap() {
  const mapString = fs
    .readFileSync(path.resolve(__dirname, './properties.json'))
    .toString()
  return JSON.parse(mapString) as IMap
}

export function resolveUrlEncodeMap() {
  const properties: string[] = []
  const properties_values: string[] = []

  properties.push('femalegenderfemale')
  properties_values.push('0')
  properties.push('malegendermale')
  properties_values.push('1')

  const map = getPropertyMap()

  // resolve male
  Object.keys(map.male).forEach((valueKey: string) => {
    const valueMap = map.male[valueKey]
    Object.keys(valueMap).forEach((value: string) => {
      const encode = valueMap[value]
      properties.push(`male${valueKey}${value}`)
      properties_values.push(encode)
    })
  })
  // resolve female
  Object.keys(map.female).forEach((valueKey: string) => {
    const valueMap = map.male[valueKey]
    Object.keys(valueMap).forEach((value: string) => {
      const encode = valueMap[value]
      properties.push(`female${valueKey}${value}`)
      properties_values.push(encode)
    })
  })

  return { properties, properties_values }
}

// export function randomBox() {}
