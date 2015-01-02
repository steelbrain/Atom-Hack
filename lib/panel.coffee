{$} = require 'atom'
class Panel
  constructor:(@main)->
    @status = 0
    @panel = null
    @panel_heading = null
    @panel_body = null
    @panel_fold_body = null
    @decorations = []
  render:->
    @decorations.forEach (decoration)-> try decoration.getMarker().destroy() catch
    @decorations = []
    if @main.errors.length < 1 then return @destroy()
    @clear if @status is 1
    editors = []
    try active_file = atom.workspace.getActiveEditor().getPath() catch then return
    for editor in atom.workspace.getEditors() then editors[editor.getPath()] = editor
    # Add the decorations first
    for error in @main.errors
      continue if typeof editors[error.file] is 'undefined'
      editor = editors[error.file]
      if error.start is error.end then error.end++
      range = [[error.line-1,error.start-1],[error.line-1,error.end]]
      marker = editor.markBufferRange(range, {invalidate: 'never'})
      @decorations.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-red'})
      @decorations.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-red'})
      for entry in error.trace
        continue if typeof editors[entry.file] is 'undefined'
        if entry.start is entry.end then entry.end++
        range = [[entry.line-1,entry.start-1],[entry.line-1,entry.end]]
        marker = editors[entry.file].markBufferRange(range, {invalidate: 'never'})
        @decorations.push editors[entry.file].decorateMarker(marker, {type: 'highlight', class: 'highlight-blue'})
        @decorations.push editors[entry.file].decorateMarker(marker, {type: 'gutter', class: 'gutter-blue'})
    errorsSelf = []
    errorsOthers = []
    for error in @main.errors
      if active_file is error.file then errorsSelf.push error
      else errorsOthers.push error
    for error in errorsSelf then @appendPointer error,active_file
    for error in errorsOthers then @otherFile error,'text-warning'
  destroy:->
    @status = 0
    $('.hh-panel').remove()
  clear:->
    if @panel_body isnt null then @panel_body.html('')
    if @panel_fold_body isnt null then @panel_fold_body.html('')
  otherFile:(error)->
    if not @status
      @init()
    content = $('<span />').append("#{error.message} at Line #{error.line} Col #{error.start} ").append(
      $('<a href="#" class="text-warning" />').text(error.file).click ->
        atom.workspace.open(error.file)
    )
    $('<div class="block text-warning" />').append(content).appendTo(@panel_body)
  appendPointer:(error,active_file)->
    if not @status
      @init()
    content = $('<span />').append("#{error.message} at Line #{error.line} Col #{error.start} ")
    content = $('<span />').append("#{error.message} at ").append(
      $('<a href="#" class="text-warning" />').text("Line ##{error.line} Col #{error.start}").click ->
        atom.workspace.getActiveEditor().cursors[0].setBufferPosition([error.line - 1, error.start - 1])
    )
    $('<div class="block text-warning" />').append(content).appendTo(@panel_body)
    if error.trace.length > 0
      trace = $('<pre style="margin-bottom:10px;" />')
      for entry in error.trace
        do ->
          coord = [entry.line-1, entry.start-1]
          file = entry.file
          if active_file is entry.file
            step = $('<span style="display:block;clear:both;" />').append("#{entry.message} at ")
            $('<a href="#" />').text("Line #{entry.line} Col #{entry.start}").appendTo(step).click ->
              atom.workspace.getActiveEditor().cursors[0].setBufferPosition(coord)
          else
            step = $('<span style="display:block;clear:both;" />').append("#{entry.message} at Line #{entry.line} Col #{entry.start} ")
            $('<a href="#" />').text('in '+file).appendTo(step).click ->
              atom.workspace.open(file)
          trace.append step
      @panel_body.append(trace)
  init:->
    self = this
    @status = 1
    @panel = $('<div class="hh-panel tool-panel panel-bottom" />')
    @panel_heading = $('<div class="panel-heading"><span class="icon-bug"></span> Hack report</div>').appendTo(@panel)
    $('<div class="icon-x pull-right" style="color:#aaa;margin-right:8px;cursor:pointer;"></div>').click(->
      self.destroy()
    ).appendTo(@panel_heading)
    @panel_body = $('<div class="panel-body padded" style="max-height:170px;overflow-y:scroll;" />').appendTo(@panel)
    $('<div class="icon-dash" style="margin-left:10px;display:none;" />').appendTo(@panel_heading)
    @panel_fold_body = $('<div style="panel-fold-body" style="display:none" />').appendTo(@panel_heading)
    atom.workspaceView.prependToBottom(@panel);
module.exports = Panel