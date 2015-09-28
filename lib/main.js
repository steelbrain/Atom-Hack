'use babel'

export default {

  Hack: null,
  config: {
    pushFilesToServer: {
      type: 'boolean',
      default: true,
      description: 'Whether or not to push files to the remote server, disable in case of local mounts'
    }
  },

  activate: function() {
    this.Hack = require('./base')
    require('atom-package-deps').install('Atom-Hack')
  },
  provideHack: function() {
    return this.Hack
  },
  provideLinter: function() {
    const Path = require('path')
    const Linter = {
      grammarScopes: ['source.hack', 'source.html.hack'],
      scope: 'project',
      lintOnFly: false,
      formatError: (error) => {
        return {
          type: 'Error',
          filePath: this.Hack.convertPath(error.path),
          text: error.descr,
          range: [[error.line - 1, error.start - 1 ],[error.line - 1, error.end]]
        }
      },
      formatErrors: function(errors) {
        const toReturn = []
        errors.errors.forEach(error => {
          const errorEntry = Linter.formatError(error.message.shift())
          errorEntry.trace = error.message.map(Linter.formatError)
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
          return this.Hack.exec('hh_client', ['--json'], {cwd: Path.dirname(filePath), stream: 'stderr'})
        }).then(function(contents) {
          try {
            return Linter.formatErrors(JSON.parse(contents))
          } catch (err) {
            return []
          }
        })
      }
    }
    return Linter
  }
}
