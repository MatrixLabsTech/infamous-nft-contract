import path from 'path'
import fs from 'fs'

export function writeFile(path: string, content: string) {
  ensureDirectoryExistence(path)
  fs.writeFileSync(path, content)
}
export function writeFileWithEnv(path: string, env: string, content: any) {
  ensureDirectoryExistence(path)
  let data = {}
  const oldFile = readFileSilence(path)
  if (oldFile) {
    data = { ...JSON.parse(oldFile), [env]: content }
    fs.writeFileSync(path, JSON.stringify(data))
  } else {
    data = { [env]: content }
    fs.writeFileSync(path, JSON.stringify(data))
  }
}
export function readFileSilence(path: string): string | undefined {
  try {
    if (fs.existsSync(path)) {
      return fs.readFileSync(path).toString()
    }
  } catch (e) {}
  return
}

function ensureDirectoryExistence(filePath: string) {
  var dirname = path.dirname(filePath)
  if (fs.existsSync(dirname)) {
    return true
  }
  ensureDirectoryExistence(dirname)
  fs.mkdirSync(dirname)
}
