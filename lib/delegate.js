/* @flow */

import SSH from 'node-ssh'
import { CompositeDisposable, Disposable } from 'atom'
import { getConfig } from './helpers'
import type { Config } from './types'

export default class Delegate {
  ssh: ?SSH;
  path: string;
  config: Config;
  subscriptions: CompositeDisposable;

  constructor(path: string) {
    this.ssh = null
    this.path = path
    this.config = { type: 'local' }
    this.subscriptions = new CompositeDisposable()

    Delegate.getConfig(path).then(config => {
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
