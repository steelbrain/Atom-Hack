
module.exports = LinterHack =
  activate: ->
    if typeof atom.packages.getLoadedPackage("linter-plus") is 'undefined'
      return @showError "[Hack] linter-plus package not found but is required to provide validations for Hack Files"
  deactivate: ->
  showError:(Message)->
    Dismissible = atom.notifications.addError Message, {dismissable: true}
    setTimeout ->
      Dismissible.dismiss()
    , 5000
  provideLinter:->
    CP = require 'child_process'
    Path = require 'path'
    return {
      scopes: ['source.hack']
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
                  Type: 'Trace',
                  Message: Message.descr,
                  File: Message.path,
                  Position: [[Message.line,Message.start],[Message.line,Message.end]]
                )
              ToReturn.push(
                Type: 'Error',
                Message: First.descr,
                File: First.path,
                Position: [[First.line,First.start],[First.line,First.end]]
                Trace: Traces
              )
            Resolve(ToReturn)
    }
