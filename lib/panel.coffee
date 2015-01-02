{$} = require 'atom'
class Panel
  constructor:()->
    @status = 0
    @panel = null
    @panel_heading = null
    @panel_body = null
    @panel_fold_body = null
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