module.exports = (Main)->
  Subscriptions = []
  Decorations = []
  Errors = []
  LeErrors = []
  Editor = atom.workspace.getActiveEditor()
  EditorView = atom.views.getView(Editor)
  ActiveFile = Editor?.getPath()
  ScrollSubscription = null
  ScrollTimeout = null
  Path = require 'path'
  class TypeChecker
    @activate:->
      return unless not Main.Status.TypeChecker
      Main.Status.TypeChecker = true
      if Editor
        ScrollSubscription = Editor.on 'scroll-top-changed',=>
          clearTimeout ScrollTimeout
          ScrollTimeout = setTimeout(@OnScroll.bind(this),100)
      Subscriptions.push atom.workspace.observeTextEditors (editor)=>
        Grammar = editor.getGrammar()
        if !Grammar or ['PHP', 'Hack', 'C++'].indexOf(Grammar.name) is -1 then return ;
        editor.buffer.onDidSave (info)=>
          @Lint()
      Subscriptions.push atom.workspace.onDidChangeActivePaneItem =>
        ScrollSubscription?.dispose()
        ScrollSubscription = null

        Editor = atom.workspace.getActiveEditor()
        EditorView = atom.views.getView(Editor)
        ActiveFile = Editor?.getPath()
        if ActiveFile
          ScrollSubscription = Editor.on 'scroll-top-changed',=>
            clearTimeout ScrollTimeout
            ScrollTimeout = setTimeout(@OnScroll.bind(this),100)
          try
            @OnScroll()
          catch error
            console.error(error.stack);
    @deactivate:->
      return unless Main.Status.TypeChecker
      Main.Status.TypeChecker = false
      Subscriptions.forEach (sub)-> sub.dispose()
      Subscriptions = []
      @RemoveDecorations()
      @RemoveErrors()
      Main.V.MPI.close()
      ScrollSubscription?.dispose()
    @Lint:->
      Main.V.H.exec(['--json'],null,ActiveFile).then (result)=>
        if result.stderr.substr(0,5) is 'Error'
          setTimeout ->
            throw new Error(result.stderr.substr(7)); # Throw an error that can not be caught
          ,0
          return ;
        try
          result = JSON.parse(result.stderr.substr(result.stderr.indexOf('{')))
        catch error
          console.log "Invalid JSON"
          console.log result
        Errors = result.errors
        if Main.V.H.config.type is 'remote'
          Errors.forEach (ErrorEntry)->
            ErrorEntry.message.forEach (ErrorMessageEntry)->
              ErrorMessageEntry.path = ErrorMessageEntry.path.replace(Main.V.H.config.remoteDir, atom.project.getPath()).split('/').join(Path.sep)
        try
          @ProcessErrors()
        catch error
          console.error(error.stack)
    @RemoveDecorations:->
      if Main.TypeCheckerDecorations.length
        Main.TypeCheckerDecorations.forEach (decoration)-> try decoration.destroy()
        Main.TypeCheckerDecorations = []
    @RemoveErrors:->
      LeErrors.forEach (error)-> error.Remove()
      LeErrors = []
    @ProcessErrors:->
      @RemoveDecorations()
      @RemoveErrors()
      return Main.V.MPI.close() unless Errors.length
      for Error,I in Errors
        LeFirst = true
        for TraceEntry in Error.message
          Color = if LeFirst then 'red' else 'blue'
          LeErrors.push new Main.V.TE(I,TraceEntry.path,TraceEntry.line,TraceEntry.start,TraceEntry.end,Color,Error.message)
          LeFirst = false
      setTimeout =>
        try @OnScroll.call(this)
      ,70
    @OnScroll:->
      RowStart = EditorView.getFirstVisibleScreenRow()
      RowEnd = EditorView.getLastVisibleScreenRow()
      LineHeight = getComputedStyle(EditorView)['line-height'];
      Main.V.MPI.clear()
      if LeErrors.length
        Main.V.MPI.attach()
        # Set a summary
        Main.V.MPI.add(new Main.V.MP.PlainMessageView(
          raw: true
          message: ''
        ))
        # Summary part ends
        LeErrors.forEach (error)->
          error.Render(RowStart,RowEnd,ActiveFile,Editor,EditorView,LineHeight)
      else
        Main.V.MPI.close()
