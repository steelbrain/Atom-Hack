/* @flow */

import Path from 'path'
import invariant from 'assert'

import SSH from 'node-ssh'
import { exec } from 'sb-exec'
import shellEscape from 'shell-escape'
import { CompositeDisposable, Disposable } from 'atom'
import { getConfig, getCmdPath } from './helpers'
import type { Config } from './types'

export default class Delegate {
  ssh: ?SSH;
  path: string;
  config: Config;
  subscriptions: CompositeDisposable;
  supportBashOnWindows: boolean;

  constructor(path: string) {
    this.ssh = null
    this.path = path
    this.config = { type: 'local' }
    this.subscriptions = new CompositeDisposable()
    this.subscriptions.add(atom.config.observe('Atom-Hack.supportBashOnWindows', (supportBashOnWindows) => {
      this.supportBashOnWindows = supportBashOnWindows
    }))

    Delegate.getConfig(path).then((config) => {
      if (config) {
        this.config = config
      }
    }).then(() => {
      if (this.config.type === 'remote') {
        this.ssh = new SSH()
        return this.ssh.connect(this.config)
      }
      return null
    }).catch(function(error) {
      atom.notifications.addWarning('[Atom-Hack] Unable to connect to SSH server', { detail: error.message })
    })
  }
  async exec(command: string, cwd: string, stdin: string = ''): Promise<{ stdout: string, stderr: string }> {
    if (this.config.type === 'local') {
      if (process.platform === 'win32' && this.supportBashOnWindows) {
        return exec(getCmdPath(), ['/c', `bash -c '${shellEscape(['hh_client', command])}'`], { cwd, stdin, stream: 'both', ignoreExitCode: true })
      }
      return exec('hh_client', [command], { cwd, stdin, stream: 'both', ignoreExitCode: true })
    }
    invariant(this.ssh)
    return this.ssh.execCommand(command, { cwd: this.toRemotePath(cwd), stdin })
  }
  async uploadFile(localFile: string) {
    if (this.config.type === 'local' || !this.config.uploadFiles) {
      return
    }
    invariant(this.ssh)
    await this.ssh.putFile(localFile, this.toRemotePath(localFile))
  }
  toLocalPath(remotePath: string): string {
    if (this.config.type === 'local') {
      if (process.platform === 'win32' && this.supportBashOnWindows) {
        const newPath = remotePath.substr(5)
        const driveLetter = newPath.indexOf('/')
        if (driveLetter === -1) {
          return newPath
        }
        return newPath.substr(0, driveLetter).toUpperCase() + ':' + newPath.substr(driveLetter)
      }
      return remotePath
    }
    return Path.join(this.path, Path.relative(this.config.remoteDirectory || '', remotePath)).split('/').join(Path.sep)
  }
  toRemotePath(localPath: string): string {
    if (this.config.type === 'local') {
      return localPath
    }
    return Path.join(this.config.remoteDirectory || '', Path.relative(this.path, localPath)).split(Path.sep).join('/')
  }
  onDidDestroy(callback: (() => void)) {
    const subscription = atom.project.onDidChangePaths(() => {
      const currentPaths = atom.project.getPaths()
      if (currentPaths.indexOf(this.path) === -1) {
        callback()
      }
    })
    const disposable = new Disposable(() => {
      this.subscriptions.remove(disposable)
      subscription.dispose()
    })
    return disposable
  }
  dispose() {
    this.subscriptions.dispose()
  }
  static async getConfig(path: string): Promise<?Config> {
    try {
      return await getConfig(path)
    } catch (error) {
      atom.notifications.addWarning(`[Atom-Hack] ${error.message}`, { detail: `This error was encountered while reading the configuration file in ${path}` })
      return null
    }
  }
}
