
module.exports = LinterHack =
  Hack: null
  activate: ->
    if typeof atom.packages.getLoadedPackage("linter-plus") is 'undefined'
      return atom.notificatons.addError "[Hack] linter-plus package not found or deactivated but is required to provide support for Hack", {dismissable: true}
    else if typeof atom.packages.getLoadedPackage("language-hack") is 'undefined'
      return atom.notificatons.addError "[Hack] language-hack package not found or deactivated but is required to provide support for Hack", {dismissable: true}
    @Hack = new (require './hack')
  provideHack: ->
    @Hack
  provideLinter:->
    Path = require 'path'
    Linter = {
      scopes: ['source.hack', 'source.html.hack']
      scope: 'project'
      lintOnFly: false
      normalizePath: (FilePath)->
        if LinterHack.Hack.config.type is 'local'
          return FilePath
        else
          Path.join(atom.project.getPaths()[0], Path.relative(LinterHack.Hack.config.remoteDir, FilePath).replace('/', Path.sep))
      formatErrors: (Content)->
        ToReturn = []
        Content.errors.forEach (ErrorEntry)->
          ErrorEntry = ErrorEntry.message
          First = ErrorEntry.shift()
          Traces = []
          for Message in ErrorEntry
            Traces.push(
              type: 'Trace',
              message: Message.descr,
              file: Linter.normalizePath(Message.path),
              position: [[Message.line,Message.start],[Message.line,Message.end]]
            )
          ToReturn.push(
            type: 'Error',
            message: First.descr,
            file: Linter.normalizePath(First.path),
            position: [[First.line,First.start],[First.line,First.end]]
            trace: Traces
          )
        ToReturn
      lint: (ActiveEditor)->
        return new Promise (Resolve)->
          FilePath = ActiveEditor.getPath()
          return Resolve([]) unless FilePath or LinterHack.Hack.config.status # Files that have not be saved
          if LinterHack.Hack.config.type is 'local' or not LinterHack.Hack.config.autoPush
            LePromise = LinterHack.Hack.exec('hh_client --json', Path.dirname(FilePath))
          else
            LePromise = LinterHack.Hack.transfer(FilePath).then ->
              LinterHack.Hack.exec('hh_client --json', Path.dirname(FilePath))
          LePromise.then (Data)->
            try
              Content = JSON.parse(Data.stderr)
            catch error then return Resolve([])# Ignore weird errors for now
            if Content.passed then Resolve([])
            else Resolve(Linter.formatErrors(Content))
          , (Error)->
            Resolve([])
            atom.notifications.addError Error.toString(), {dismissible: true}
    }
