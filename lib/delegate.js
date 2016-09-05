/* @flow */

import { CompositeDisposable, Disposable } from 'atom'

export default class Delegate {
  path: string;
  subscriptions: CompositeDisposable;

  constructor(path: string) {
    this.path = path
    this.subscriptions = new CompositeDisposable()
    console.log('delegate for ', this.path)
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
}
