/* @flow */

import FS from 'fs'
import Path from 'path'
import { promisifyAll } from 'sb-promisify'
import type { Config } from './types'

const promisedFS = promisifyAll(FS)

export async function getConfig(projectPath: string): Promise<?Config> {
  const configFile = Path.join(projectPath, '.atom-hack.json')
  try {
    await promisedFS.accessAsync(configFile, FS.R_OK)
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null
    }
    throw error
  }

  const contents = { type: 'local', uploadFiles: true }
  try {
    Object.assign(contents, JSON.parse(await promisedFS.readFile(configFile, 'utf8')))
  } catch (error) {
    if (error.name === 'SyntaxError') {
      throw new Error('Malformed JSON found in Config file')
    }
    throw error
  }
  if (typeof contents !== 'object' || !contents) {
    throw new Error('Config file is invalid')
  }
  if (contents.type === 'local') {
    return contents
  }
  if (typeof contents.host !== 'string' || !contents.host) {
    throw new Error('host in config file is invalid')
  }
  if (typeof contents.username !== 'string' || !contents.username) {
    throw new Error('username in config file is invalid')
  }
  if (typeof contents.privateKey !== 'string' || !contents.privateKey) {
    throw new Error('privateKey in config file is invalid')
  }
  if (typeof contents.remoteDirectory !== 'string' || !contents.remoteDirectory) {
    throw new Error('remoteDirectory in config file is invalid')
  }
  return contents
}
