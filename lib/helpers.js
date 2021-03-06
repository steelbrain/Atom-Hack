/* @flow */

import FS from 'fs'
import Path from 'path'
import { promisifyAll } from 'sb-promisify'
import type Delegate from './delegate'
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

export function parseError(error: Object, type: string, delegate: Delegate): Object {
  return {
    type,
    filePath: delegate.toLocalPath(error.path),
    text: error.descr,
    range: [[error.line - 1, error.start - 1], [error.line - 1, error.end]],
  }
}

export function parseErrors(givenContents: string, delegate: Delegate): Array<Object> {
  let contents = givenContents
  const startingPoint = contents.indexOf('{')
  if (startingPoint === -1) {
    return []
  }
  contents = contents.substr(startingPoint)
  let errors = []
  try {
    const parsed = JSON.parse(contents)
    errors = parsed.errors || errors
  } catch (_) {
    console.error('[Atom-Hack] Unable to parse contents', givenContents)
  }
  return errors.map(function(error) {
    const linterError = parseError(error.message.shift(), 'Error', delegate)
    linterError.trace = error.message.map(e => parseError(e, 'Trace', delegate))
    return linterError
  })
}

export function getCmdPath(): string {
  let windir = process.env.windir
  if (!windir) {
    console.warn('[Atom-Hack] windir env variable not found')
    windir = 'C:\\WINDOWS'
  }
  return `${windir}\\${process.arch === 'ia32' ? 'Sysnative' : 'System32'}\\cmd.exe`
}

export function wait(timeout: number): Promise<void> {
  return new Promise(function(resolve) {
    setTimeout(resolve, timeout)
  })
}
