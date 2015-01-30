{$, View} = require 'atom'

module.exports = (Main)->
  class Error
    constructor:(@Num, @File,@Line,@Start,@End,@Color,@Trace)->
      @Element = null
      @Status = false
      @Range = [[Line-1,Start-1],[Line-1,End]]
    Remove:->
      @Element?.off('mouseenter.atom-hack mouseleave.atom-hack');
    Render:(RowStart,RowEnd,ActiveFile,Editor,EditorView)->
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
      setTimeout =>
        @Element = $(EditorView.querySelector('atom-text-editor /deep/ .atom-hack-'+@Num))
        @Element.on 'mouseenter.atom-hack mouseleave.atom-hack',@onHover.bind(this)
      ,70
    onHover:(e)->
      if @Status
        # Remove the tooltip for it's a mouseleave
        console.log "Remove"
      else
        # Add the tooltip for it's a mouseenter
        console.log "Add"
      @Status = !@Status