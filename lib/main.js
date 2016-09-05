/* @flow */

import { CompositeDisposable } from 'atom'
import type { TextEditor } from 'atom'

import DelegateRegistry from './delegate-registry'

let delegates
let subscriptions

const atomHackPackage = {
  config: {
    hackExecutablePath: {
      type: 'string',
      default: 'hh_client',
    },
  },

  activate() {
    require('atom-package-deps').install('Atom-Hack') // eslint-disable-line global-require
    delegates = new DelegateRegistry()
    subscriptions = new CompositeDisposable()
    subscriptions.add(delegates)
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
        console.log('linting a hack file', textEditor.getPath())
        return []
      },
    }
  },
}

export default atomHackPackage
