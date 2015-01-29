{$, View} = require 'atom'

module.exports = (Main)->
  Subscription = null
  WorkSpaceView = null
  TooltipInstance = null
  ActiveFile = null
  Errors = {}
  Decorations = []
  class TypeChecker
    @activate:->
      return unless !Main.Status.TypeChecker
      Main.Status.TypeChecker = true
      Subscription = atom.workspace.observeTextEditors (editor)=>
        editor.buffer.onDidSave (info)=>
          ActiveFile = info.path
          @removeDecorations()
          @lint(editor)
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
    @lint:(editor)->
      Main.V.H.exec(['--json'],null,ActiveFile).then (result)=>
        result = JSON.parse(result.stderr)
        return if result.passed
        WorkSpaceView?.off 'click.atom-hack'
        WorkSpaceView = atom.workspaceView.getActiveView()
        WorkSpaceView.on 'click.atom-hack',(e)=>
          cursors = editor.getCursorBufferPosition()
          return TooltipInstance?.remove() if typeof Errors[cursors.row+1] is 'undefined'
          current = null
          Errors[cursors.row+1].forEach (info)->
            if cursors.column >= info.start-1 and cursors.column <= info.end
              current = info
          return unless current?
          try
            @errorTooltip(current,cursors,e)
          catch error
            console.log error
        result.errors.forEach (error)=>
          @errorProcess error.message,editor
    @errorTooltip:(error,cursors,e)->
      TooltipInstance?.remove()
      offset = WorkSpaceView.lineHeight * 0.7
      TooltipInstance = new Main.V.TT(
        left: e.clientX
        right: e.clientX
        top: e.clientY - offset
        bottom: e.clientY + offset
      ,@errorMessage(error,cursors))
    @errorMessage:(error,cursor)->
      if error.trace[0].line - 1 is cursor.row
        message = $("<span>#{error.trace[0].descr}<br></span>")
        error.trace.slice(1).forEach (entry)=>
          message.append @errorClickable(entry)
          message.append "<br>"
      else
        message = @errorClickable(error.trace[0])
      return message
    @errorClickable:(error)->
      if error.path is ActiveFile
        return $("<span>#{error.descr} on </span>").append(
          $("<a href='#'>Line #{error.line} Col #{error.start} </a>").click ->
            atom.workspace.open(error.path).then ->
              atom.workspace.getActiveEditor().setCursorBufferPosition [error.line-1,error.start-1]
              TooltipInstance?.remove()
        );
      else
        return $("<span>#{error.descr} on </span>").append(
          $("<a href='#'>Line #{error.line} Col #{error.start} in #{error.path}</a>").click ->
            atom.workspace.open(error.path).then ->
              atom.workspace.getActiveEditor().setCursorBufferPosition [error.line-1,error.start-1]
              TooltipInstance?.remove()
        );
    @errorProcess:(errors,editor)->
      first = true
      for error in errors
        color = if first then 'red' else 'blue'
        first = false
        if error.path is ActiveFile
          @errorIndex error,errors
          @errorMark error,editor,color
    @errorIndex:(error,errors)->
      Errors[error.line] = Errors[error.line] || []
      Errors[error.line].push start:error.start,end:error.end,trace:errors
    @errorMark:(error,editor,color)->
      range = [[error.line-1,error.start-1],[error.line-1,error.end]]
      marker = editor.markBufferRange(range, {invalidate: 'never'})
      Decorations.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-'+color})
      Decorations.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-'+color})