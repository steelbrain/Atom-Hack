
module.exports = LinterHack =
  Hack: null
  activate: ->
    if typeof atom.packages.getLoadedPackage("linter-plus") is 'undefined'
      return @showError "linter-plus package not found or deactivated but is required to provide support for Hack"
    HackClass = require './hack'
    @Hack = new HackClass
  showError:(Message)->
    Dismissible = atom.notifications.addError "[Hack] " + Message, {dismissable: true}
    setTimeout ->
      Dismissible.dismiss()
    , 5000
  provideHack: ->
    @Hack
  provideLinter:->
    CP = require 'child_process'
    Path = require 'path'
    return {
      scopes: ['source.hack', 'source.html.hack']
      scope: 'project'
      lintOnFly: false
      lint: (ActiveEditor)->
        return new Promise (Resolve)->
          FilePath = ActiveEditor.getPath()
          return unless FilePath # Files that have not be saved
          Data = []
          Process = CP.exec('hh_client --json', {cwd: Path.dirname(FilePath)})
          Process.stderr.on 'data', (data)-> Data.push(data.toString())
          Process.on 'close', ->
            try
              Content = JSON.parse(Data.join(''))
            catch error then return # Ignore weird errors for now
            return Resolve([]) if Content.passed
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
            Resolve(ToReturn)
    }
