/* @flow */

import Path from 'path'
import { CompositeDisposable } from 'atom'
import type { TextEditor } from 'atom'

import { parseErrors, wait } from './helpers'
import DelegateRegistry from './delegate-registry'

let delegates
let subscriptions

const atomHackPackage = {
  activate() {
    require('atom-package-deps').install('Atom-Hack') // eslint-disable-line global-require

    delegates = new DelegateRegistry()
    subscriptions = new CompositeDisposable()
    subscriptions.add(delegates)
    delegates.activate()
    // TODO: Use intentions goto declaration
  },
  deactivate() {
    subscriptions.dispose()
  },
  provideDelegateRegistry() {
    return delegates
  },
  provideLinter() {
    return {
      name: 'Atom-Hack',
      scope: 'project',
      lintOnFly: false,
      grammarScopes: ['source.hack', 'source.html.hack'],
      async lint(textEditor: TextEditor) {
        const localPath = textEditor.getPath()
        const delegate = delegates.getDelegateForPath(localPath)
        if (!delegate) {
          return []
        }
        await delegate.uploadFile(localPath)
        await wait(500)
        const results = await delegate.exec('--json', Path.dirname(localPath))
        return parseErrors(results.stderr || results.stdout || '{}', delegate)
      },
    }
  },
}

export default atomHackPackage
