/* @flow */

import { CompositeDisposable } from 'atom'
import Delegate from './delegate'

export default class DelegateRegistry {
  delegates: Set<Delegate>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.delegates = new Set()
    this.subscriptions = new CompositeDisposable()
  }
  activate() {
    const paths = atom.project.getPaths()
    let lastLength = paths.length

    this.subscriptions.add(atom.project.onDidChangePaths(() => {
      const newPaths = atom.project.getPaths()
      if (lastLength < newPaths.length) {
        newPaths.forEach(path => this.createDelegate(path))
      }
      lastLength = newPaths.length
    }))
    paths.forEach(path => this.createDelegate(path))
  }
  createDelegate(path: string) {
    if (this.getDelegateForPath(path)) {
      return
    }

    const delegate = new Delegate(path)
    this.delegates.add(delegate)
    delegate.onDidDestroy(() => {
      this.delegates.delete(delegate)
    })
  }
  getDelegateForPath(path: string): ?Delegate {
    for (const entry of this.delegates) {
      if (entry.path === path) {
        return entry
      }
    }
    return null
  }
  dispose() {
    this.subscriptions.dispose()
    this.delegates.forEach(function(delegate) {
      delegate.dispose()
    })
  }
}
