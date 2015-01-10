{Subscriber} = require 'emissary'
{TooltipView} = require './tooltip-view'
spawn = require('child_process').spawnSync


class Tooltip
  constructor:(@editorView,@editor,@Main)->
    @subscriber = new Subscriber()
    @gutter = @editorView.gutter
    @scroll = @editorView.find('.scroll-view')

    @Timeout = null
    @TooltipInstance = null

    # show expression type if mouse stopped somewhere
    @subscriber.subscribe @scroll, 'mousemove', (e) =>
      do @clearTooltip
      @Timeout = setTimeout =>
        @showDetail(e);
      , 100
    @subscriber.subscribe @scroll, 'mouseout',=>
      do @clearTooltip
    Disposable = atom.workspace.onDidChangeActivePaneItem =>
      do @clearTooltip
      do Disposable.dispose
      do @subscriber.unsubscribe
  clearTooltip:->
    clearTimeout @Timeout
    if @TooltipInstance?
      @TooltipInstance.remove()
      @TooltipInstance = null
  showDetail:(e)->
    try
      Position = @editor.bufferPositionForScreenPosition @editor.screenPositionForPixelPosition @PixelFromEvent(e)
      curCharPixelPt = @editor.pixelPositionForBufferPosition([Position.row, Position.column])
      nextCharPixelPt = @editor.pixelPositionForBufferPosition([Position.row, Position.column + 1])
      return if curCharPixelPt.left >= nextCharPixelPt.left
      # find out show position
      offset = @editorView.lineHeight * 0.7
      tooltipRect =
        left: e.clientX
        right: e.clientX
        top: e.clientY - offset
        bottom: e.clientY + offset
      # create tooltip with pending
      @TooltipInstance = new TooltipView(tooltipRect)
      @PositionType
        Position: Position
        fileName: @editor.getPath()
        text: @editor.getText()
    catch
  PositionType:(args)->
    Result = spawn "hh_client",['--type-at-pos',(args.Position.row+1)+':'+(args.Position.column+1)],{cwd:@Main.getProjectRoot(),input:args.text}
    Result = Result.stdout.toString().trim();
    if Result is '_' or Result is '(unknown)' # '_' is for global functions, '(unknown)' is for class methods
      @PositionFunction(args)
    else
      @TooltipInstance?.updateText(Result)
  PositionFunction:(args)->
    Result = spawn "hh_client",['--identify-function',(args.Position.row+1)+':'+(args.Position.column+1)],{cwd:@Main.getProjectRoot(),input:args.text}
    Result = Result.stdout.toString().trim();
    @TooltipInstance?.updateText(Result)
  PixelFromEvent:(e)->
    {clientX, clientY} = e
    linesClientRect = @editorView.find('.lines')[0].getBoundingClientRect()
    top = clientY - linesClientRect.top
    left = clientX - linesClientRect.left
    {top, left}

module.exports = Tooltip