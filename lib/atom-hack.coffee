
module.exports = LinterHack =
  Hack: null
  activate: ->
    if typeof atom.packages.getLoadedPackage("linter-plus") is 'undefined'
      return atom.notificatons.addError "linter-plus package not found or deactivated but is required to provide support for Hack", {dismissable: true}
    HackClass = require './hack'
    @Hack = new HackClass
  provideHack: ->
    @Hack
  provideLinter:->
    Path = require 'path'
    return Linter = {
      scopes: ['source.hack', 'source.html.hack']
      scope: 'project'
      lintOnFly: false
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
              file: Message.path,
              position: [[Message.line,Message.start],[Message.line,Message.end]]
            )
          ToReturn.push(
            type: 'Error',
            message: First.descr,
            file: First.path,
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
