{$, View} = require 'atom'

module.exports = (Main)->
  class Error
    constructor:(@Num, @File,@Line,@Start,@End,@Color,@Trace)->
      @Element = null
      @ActiveFile = null
      @Status = false
      @Tooltip = null
      @LineHeight = 1
      @Timeout = null
      @Range = [[Line-1,Start-1],[Line-1,End]]
    Remove:->
      @Element?.off('mouseenter.atom-hack mouseleave.atom-hack');
      if @Status
        @MouseLeave()
    Render:(RowStart,RowEnd,@ActiveFile,Editor,EditorView,LineHeight)->
      if @Element isnt null
        if @Element.height() is 0
          @Element = null
        else
          @Element.off('mouseenter.atom-hack mouseleave.atom-hack');
      return if ActiveFile isnt @File
      Marker = Editor.markBufferRange(@Range, {invalidate: 'never'})
      Main.TypeCheckerDecorations.push Editor.decorateMarker(Marker, {type: 'highlight', class: 'highlight-'+@Color})
      Main.TypeCheckerDecorations.push Editor.decorateMarker(Marker, {type: 'gutter', class: 'gutter-'+@Color})
      Main.TypeCheckerDecorations.push Editor.decorateMarker(Marker, {type: 'gutter', class: 'atom-hack-'+@Num})
      return if @Line-1 >= RowEnd or @Line <= RowStart
      @LineHeight = parseInt(LineHeight)
      setTimeout =>
        @Element = $(EditorView.querySelector('atom-text-editor /deep/ .atom-hack-'+@Num))
        @Element.on 'mouseenter.atom-hack',@MouseEnter.bind(this)
        @Element.on 'mouseleave.atom-hack',@MouseLeave.bind(this)
      ,70
    MouseEnter:(e)->
      clearTimeout @Timeout
      @Timeout = setTimeout =>
        @Status = true
        @TooltipCreate e
      ,300
    MouseLeave:(e)->
      clearTimeout @Timeout
      @Timeout = setTimeout =>
        @Status = false
        @Tooltip?.remove()
        @Tooltip = null
      ,300
    TooltipCreate:(e)->
      Rect =
        left: e.clientX
        right: e.clientX
        top: e.clientY - (@LineHeight * 0.7)
        bottom: e.clientY + (@LineHeight * 0.7)
      @Tooltip = new Main.V.TT(Rect,@TooltipContent())
      @Tooltip.on 'mouseenter',=>
        clearTimeout @Timeout
        @Tooltip.on 'mouseleave',=>
          @Tooltip.remove()
          @Tooltip = null
    TooltipContent:->
      Parent = $('<div></div>')
      for Error in @Trace
        ((Error)=>
          Text = "at Line #{Error.line} Col #{Error.start}"
          if Error.path isnt @ActiveFile
            Text += " in #{Error.path}"
          Parent.append(
            $("<span>#{Error.descr} </span>").append(
              $("<a href='#'>#{Text}</a>").click =>
                @TooltipJump Error
            )
          )
        )(Error);
      return Parent
    TooltipJump:(Error)->
      atom.workspace.open(Error.path).then ->
        atom.workspace.getActiveEditor().setCursorBufferPosition [Error.line-1,Error.start-1]