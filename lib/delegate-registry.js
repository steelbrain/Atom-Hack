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
    let chosenPath

    const delegates = Array.from(this.delegates)
    const paths = delegates.map(d => d.path).sort(function(a, b) {
      if (a.length < b.length) {
        return 1
      } else if (b.length < a.length) {
        return -1
      }
      return 0
    })
    for (let i = 0, length = paths.length; i < length; ++i) {
      if (paths[i].indexOf(path) !== -1) {
        chosenPath = paths[i]
        break
      }
    }
    if (chosenPath) {
      for (let i = 0, length = delegates.length; i < length; ++i) {
        if (delegates[i].path === chosenPath) {
          return delegates[i]
        }
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
