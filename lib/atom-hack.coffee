
module.exports = LinterHack =
  Hack: null
  activate: ->
    if typeof atom.packages.getLoadedPackage("linter") is 'undefined'
      return atom.notifications.addError "[Hack] linter package not found or deactivated but is required to provide support for Hack", {dismissable: true}
    else if typeof atom.packages.getLoadedPackage("language-hack") is 'undefined'
      return atom.notifications.addError "[Hack] language-hack package not found or deactivated but is required to provide support for Hack", {dismissable: true}
    @Hack = new (require './hack')
  provideHack: ->
    @Hack
  provideLinter:->
    Path = require 'path'
    Linter = {
      grammarScopes: ['source.hack', 'source.html.hack']
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
              text: Message.descr,
              filePath: Linter.normalizePath(Message.path),
              range: [[Message.line - 1,Message.start - 1 ],[Message.line - 1 ,Message.end]]
            )
          ToReturn.push(
            type: 'Error',
            text: First.descr,
            filePath: Linter.normalizePath(First.path),
            range: [[First.line - 1, First.start - 1 ],[First.line - 1,First.end]]
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
