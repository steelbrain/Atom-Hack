module.exports = (Main)->
  Subscription = null
  Decorations = []
  class TypeChecker
    @activate:->
      return unless !Main.Status.TypeChecker
      Main.Status.TypeChecker = true
      Subscription = atom.workspace.observeTextEditors (editor)=>
        editor.buffer.onDidSave (info)=>
          @removeDecorations()
          @lint(info.path,editor)
    @deactivate:->
      return unless Main.Status.TypeChecker
      Subscription?.dispose();
      Main.Status.TypeChecker = false
    @removeDecorations:->
      Decorations.forEach (decoration)->
        try decoration.destroy()
      Decorations = []
    @lint:(path,editor)->
      currentFile = editor.getPath()
      Main.V.H.exec(['--json'],null,path).then (result)=>
        result = JSON.parse(result.stderr)
        return if result.passed
        result.errors.forEach (error)=>
          @errorProcess error.message,editor,currentFile
    @errorProcess:(errors,editor,currentFile)->
      for error in errors
        if error.path is currentFile
          @errorMark(error,editor,'red')
    @errorMark:(error,editor,color)->
      console.log(error)
      range = [[error.line-1,error.start-1],[error.line-1,error.end]]
      marker = editor.markBufferRange(range, {invalidate: 'never'})
      Decorations.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-'+color})
      Decorations.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-'+color})