
module.exports = AtomHack =
  Hack: null
  activate: ->
    @Hack = new (require './hack')
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
        if AtomHack.Hack.config.type is 'local'
          FilePath
        else
          Path.join(atom.project.getPaths()[0], Path.relative(AtomHack.Hack.config.remoteDir, FilePath).replace('/', Path.sep))
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
          return Resolve([]) unless FilePath or AtomHack.Hack.config.status # Files that have not be saved
          if AtomHack.Hack.config.type is 'local' or not AtomHack.Hack.config.autoPush
            FileName = FilePath.split(Path.sep).pop();
            LePromise = AtomHack.Hack.exec('touch ' + FileName, Path.dirname(FilePath)).then ->
                AtomHack.Hack.exec('hh_client --json', Path.dirname(FilePath))
          else
            LePromise = AtomHack.Hack.transfer(FilePath).then ->
              AtomHack.Hack.exec('hh_client --json', Path.dirname(FilePath))
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
