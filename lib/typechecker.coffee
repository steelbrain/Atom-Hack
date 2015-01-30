{$, View} = require 'atom'

module.exports = (Main)->
  Subscriptions = []
  Decorations = []
  Errors = []
  Editor = atom.workspace.getActiveEditor()
  EditorView = atom.views.getView(atom.workspace)
  ActiveFile = Editor?.getPath()
  TooltipInstance = null
  class TypeChecker
    @activate:->
      return unless !Main.Status.TypeChecker
      Main.Status.TypeChecker = true
      Subscriptions.push atom.workspace.observeTextEditors (editor)=>
        editor.buffer.onDidSave (info)=>
          @Lint()
      Subscriptions.push atom.workspace.onDidChangeActivePaneItem =>
        EditorView?.off 'click.atom-hack'
        EditorView = atom.views.getView(atom.workspace)
        Editor = atom.workspace.getActiveEditor()
        ActiveFile = Editor?.getPath()
        try
          @ProcessErrors()
        catch error
          console.error(error.stack);
    @deactivate:->
      return unless Main.Status.TypeChecker
      Main.Status.TypeChecker = false
      Subscriptions.forEach (sub)-> sub.dispose()
      Subscriptions = []
      Decorations.forEach (decoration)-> try decoration.destroy()
      Decorations = []
      TooltipInstance?.remove()
    @Lint:->
      Main.V.H.exec(['--json'],null,ActiveFile).then (result)=>
        result = JSON.parse(result.stderr)
        Errors = result.errors
        try
          @ProcessErrors()
        catch error
          console.error(error.stack)
    @ProcessErrors:->
      # Remove Decorations
      if Decorations.length
        Decorations.forEach (decoration)-> try decoration.destroy()
        Decorations = []
      TooltipInstance?.remove()
      return unless Errors.length
      # TODO: Add .on to listen clicks and show tooltips
      EditorView?.off 'click.atom-hack'
      I = 0
      for Error in Errors
        LeFirst = true
        for TraceEntry in Error.message
          ++I
          ((I)->
            Color = if LeFirst then 'red' else 'blue'
            LeFirst = false
            if TraceEntry.path is ActiveFile
              # TODO: Add this to an indexed error storage to be used to show tooltips
              LeRange = [[TraceEntry.line-1,TraceEntry.start-1],[TraceEntry.line-1,TraceEntry.end]]
              marker = Editor.markBufferRange(LeRange, {invalidate: 'never'})
              Decorations.push Editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-'+Color})
              Decorations.push Editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-'+Color})
              Decorations.push Editor.decorateMarker(marker, {type: 'gutter', class: 'atom-hack-'+I})
              setTimeout =>
                #TODO: Attach the hover event here
                EditorView.find('.atom-hack-'+I)
              ,100
          )(I)