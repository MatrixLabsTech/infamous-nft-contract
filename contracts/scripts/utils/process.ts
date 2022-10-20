import { output } from './base'

export function asset(beTrue: boolean, reason: string) {
  if (!beTrue) {
    output('error', reason)
    process.exit(1)
  }
}
