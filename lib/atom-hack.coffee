
module.exports = LinterHack =
  activate: ->
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
      lint: (ActiveEditor, _, {Error, Trace})->
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
              First = ErrorEntry[0]
              Traces = []
              for Message in ErrorEntry.slice(1)
                Traces.push new Trace Message.descr, Message.path, [[Message.line,Message.start],[Message.line,Message.end]]
              ToReturn.push new Error First.descr, First.path, [[First.line,First.start],[First.line,First.end]], Traces
            Resolve(ToReturn)
    }
