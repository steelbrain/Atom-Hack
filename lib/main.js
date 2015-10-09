'use babel'

const Path = require('path')
import {CompositeDisposable} from 'atom'

export default {

  Hack: null,
  config: {
    hackExecutablePath: {
      type: 'string',
      default: 'hh_client'
    }
  },

  activate: function() {
    this.subscriptions = new CompositeDisposable
    this.Hack = require('./base')
    require('atom-package-deps').install('Atom-Hack')

    this.subscriptions.add(atom.commands.add('atom-text-editor[data-grammar~=hack]', 'symbols-view:go-to-declaration', () => {
      if (!this.Hack.connected) {
        return // No-Op
      }
      const textEditor = atom.workspace.getActiveTextEditor()
      if (!textEditor || !textEditor.getPath()) {
        return // Ignore
      }
      const position = textEditor.getCursorBufferPosition()
      const exePath = atom.config.get('Atom-Hack.hackExecutablePath')
      this.Hack.exec(exePath, ['--identify-function', (position.row + 1) + ':' + (position.column + 1)], {stdin: textEditor.getText(), cwd: Path.dirname(textEditor.getPath())})
        .then(contents => {
          if (!contents) {
            return // It must be an invalid position
          }
          this.Hack.exec(exePath, ['--search', contents, '--json'], {cwd: Path.dirname(textEditor.getPath())})
            .then(JSON.parse).then(contents => {
              if (!contents.length) {
                return // Nothing found
              }
              atom.workspace.open(this.Hack.convertPath(contents[0].filename, false)).then(function() {
                atom.workspace.getActiveTextEditor().setCursorBufferPosition([contents[0].line - 1, contents[0].char_start - 1])
              })
            })
        })
    }))
  },
  deactivate: function() {
    this.subscriptions.dispose()
  },
  provideHack: function() {
    return this.Hack
  },
  provideLinter: function() {
    const Linter = {
      grammarScopes: ['source.hack', 'source.html.hack'],
      scope: 'project',
      lintOnFly: false,
      name: 'Atom-Hack',
      formatError: (error) => {
        return {
          type: 'Error',
          filePath: this.Hack.convertPath(error.path, false),
          text: error.descr,
          range: [[error.line - 1, error.start - 1 ],[error.line - 1, error.end]]
        }
      },
      formatErrors: function(errors) {
        const toReturn = []
        errors.errors.forEach(error => {
          const errorEntry = Linter.formatError(error.message.shift())
          errorEntry.trace = error.message.map(Linter.formatError)
          errorEntry.trace.forEach(e => e.type = 'Trace')
          toReturn.push(errorEntry)
        })
        return toReturn
      },
      lint: textEditor => {
        const filePath = textEditor.getPath()
        if (!this.Hack.connected) {
          return []
        }
        return this.Hack.update(filePath).then(() => {
          return this.Hack.exec(atom.config.get('Atom-Hack.hackExecutablePath'), ['--json'], {cwd: Path.dirname(filePath), stream: 'stderr'})
        }).then(function(contents) {
          try {
            return Linter.formatErrors(JSON.parse(contents))
          } catch (err) {
            console.error(err)
            return []
          }
        })
      }
    }
    return Linter
  }
}
