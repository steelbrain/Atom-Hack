'use strict';
module.exports = (Main)->
  Subscription = null
  WorkSpaceView = null
  TooltipInstance = null
  Errors = {}
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
      Subscription?.dispose()
      TooltipInstance?.remove()
      WorkSpaceView?.off 'click.atom-hack'
      Main.Status.TypeChecker = false
    @removeDecorations:->
      if Decorations.length
        Decorations.forEach (decoration)->
          try decoration.destroy()
        Decorations = []
    @lint:(path,editor)->
      currentFile = editor.getPath()
      Main.V.H.exec(['--json'],null,path).then (result)=>
        result = JSON.parse(result.stderr)
        return if result.passed
        WorkSpaceView?.off 'click.atom-hack'
        WorkSpaceView = atom.workspaceView.getActiveView()
        WorkSpaceView.on 'click.atom-hack',(e)=>
          cursors = editor.getCursorBufferPosition()
          return TooltipInstance?.remove() if typeof Errors[cursors.row] is 'undefined'
          current = null
          Errors[cursors.row].forEach (info)->
            if cursors.column >= info.start and cursors.column <= info.end
              current = info
          return unless current?
          @errorTooltip(current,e)
        result.errors.forEach (error)=>
          @errorProcess error.message,editor,currentFile
    @errorTooltip:(error,e)->
      TooltipInstance?.remove()
      offset = WorkSpaceView.lineHeight * 0.7
      TooltipInstance = new Main.V.TT(
        left: e.clientX
        right: e.clientX
        top: e.clientY - offset
        bottom: e.clientY + offset
      ,error.message)
    @errorProcess:(errors,editor,currentFile)->
      first = true
      for error in errors
        error.line--;
        error.start--;
        color = if first then 'red' else 'blue'
        first = false
        if error.path is currentFile
          @errorIndex error
          @errorMark error,editor,color
    @errorIndex:(error)->
      Errors[error.line] = Errors[error.line] || []
      Errors[error.line].push start:error.start,end:error.end,message:error.descr
    @errorMark:(error,editor,color)->
      range = [[error.line,error.start],[error.line,error.end]]
      marker = editor.markBufferRange(range, {invalidate: 'never'})
      Decorations.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-'+color})
      Decorations.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-'+color})