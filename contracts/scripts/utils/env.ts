import dotenv from 'dotenv'
import dotenvExpand from 'dotenv-expand'

export interface IEnv {
  DEPLOYER_PRIVATE_KEY?: string
  DEPLOYER_ADDRESS?: string
  ADDRESS_MAP?: string
  NODE_ENV: string
}

export function configAndGetParams(): IEnv {
  const envFlag = process.argv[2]
  if (envFlag && envFlag.startsWith('--')) {
    const env = envFlag.substring(2)
    return { NODE_ENV: env }
  } else {
    return { NODE_ENV: '' }
  }
}
