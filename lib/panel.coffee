{$} = require 'atom'
path = require 'path'


module.exports = (Main)->
  Panel = new class
    status:false
    constructor:->
      @Panel = null
      @PanelBody = null
      @PanelHead = null
      @children = []
      Main.Disposables.push atom.workspace.onDidChangeActivePaneItem =>
        try
          for child in @children
            do child.render
    init:->
      return if @status
      @status = true
      @Panel = $('<div class="hh-panel tool-panel panel-bottom" />')
      @Panel = $('<div class="hh-panel tool-panel panel-bottom" />')
      @PanelHead = $('<div class="panel-heading"><span class="icon-bug"></span> Hack report</div>').appendTo(@Panel)
      $('<div class="icon-x pull-right" style="color:#aaa;margin-right:8px;cursor:pointer;"></div>').click(=>do @destroy).appendTo(@PanelHead)
      @PanelBody = $('<div class="panel-body padded" style="max-height:170px;overflow-y:scroll;" />').appendTo(@Panel)
      $('<div class="icon-dash" style="margin-left:10px;display:none;" />').appendTo(@PanelHead)
      $('<div style="panel-fold-body" style="display:none" />').appendTo(@PanelHead)
      atom.workspaceView.prependToBottom(@Panel);
    destroy:->
      return if @status is false
      @status = false
      do @Panel?.remove
      do @PanelHead?.remove
      do @PanelBody?.remove
      @Panel = null
      @PanelHead = null
      @PanelBody = null
      for child in @children
        do child.destroy
    update:->
      active = false
      for child in @children
        if child.status then active = true
      if active isnt true
        do @destroy
  PanelSection = class
    constructor:(@Title,@color)->
      @status = false
      @messages = []
      @deco = []
      Panel.children.push this
    add:(messages)->
      @messages = messages
      do @render
    render:->
      if @messages.length <1
        do @destroy
      else
        if @status
          do @removeDeco
          do @clear
        else
          do @init
        do @__render
    __render:->
      @head.children('.count').html(@messages.length)
      editors = {}
      editor = atom.workspace.getActiveEditor()
      activeFile = do editor.getPath
      for leEditor in atom.workspace.getEditors() then try editors[leEditor.getPath()] = leEditor
      CurrentFileEntries = []
      OtherFileEntries = []
      for message in @messages
        if message instanceof PlainMessage || message.File isnt activeFile
          OtherFileEntries.push message
        else
          CurrentFileEntries.push message
      i = 0
      for LeMessage in CurrentFileEntries
        do =>
          message = LeMessage
          ++i
          Info = {File:message.File,Start:message.Start,Line:message.Line}
          content = $('<span />').append("#{i}. #{message.Message} at ")
          .append $('<a href="#" class="text-warning" />').text("Line ##{message.Line} Col #{message.Start}").click ->
            Main.openFile(Info.File,Info.Line,Info.Start)
          marker = editor.markBufferRange([[message.Line-1,message.Start-1],[message.Line-1,message.End]], {invalidate: 'never'})
          @deco.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-'+@color})
          @deco.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-'+@color})
          $('<div class="block" />').append(content).appendTo(@panel)
          if message.Trace.length > 0
            trace = $('<pre style="margin-bottom:10px;" />')
            for DeEntry in message.Trace
              do =>
                entry = DeEntry
                if typeof editors[entry.File] isnt 'undefined'
                  marker = editors[entry.File].markBufferRange([[entry.Line-1,entry.Start-1],[entry.Line-1,entry.End]], {invalidate: 'never'})
                  @deco.push editors[entry.File].decorateMarker(marker, {type: 'highlight', class: 'highlight-blue'})
                  @deco.push editors[entry.File].decorateMarker(marker, {type: 'gutter', class: 'gutter-blue'})
                LeInfo = {File:entry.File,Start:entry.Start,Line:entry.Line}
                if entry.File is activeFile
                  step = $('<span style="display:block;clear:both;" />').append("#{entry.Message} at ")
                  $('<a href="#" />').text("Line #{entry.Line} Col #{entry.Start}").appendTo(step).click ->
                    Main.openFile(LeInfo.File,LeInfo.Line,LeInfo.Start)
                else
                  step = $('<span style="display:block;clear:both;" />').append("#{entry.Message} in ")
                  $('<a href="#" />').text("#{entry.File.replace(atom.project.path+path.sep,'')} at Line #{entry.Line} Col #{entry.Start}").appendTo(step).click ->
                    Main.openFile(LeInfo.File,LeInfo.Line,LeInfo.Start)
                trace.append step
            @panel.append trace
      for message in OtherFileEntries
        do =>
          ++i
          if message instanceof PlainMessage
            content = $('<span />').append("#{i}. #{message.Message}")
          else
            Info = {File:message.File,Line:message.Line,Start:message.Start}
            content = $('<span />').append("#{i}. #{message.Message} in ")
            .append $('<a href="#" class="text-warning" />').text("#{message.File.replace(atom.project.path+path.sep,'')} at Line ##{message.Line} Col #{message.Start}").click ->
              Main.openFile(Info.File,Info.Line,Info.Start)
          $('<div class="block" />').append(content).appendTo(@panel)
    init:->
      @status = true
      @panel = $("<div style='padding-left:15px' />")
      button = $("<a href='javascript:void(0)'>✘</a>").click(=>do @destroy)
      @head = $("<h6><span class='count'></span> #{@Title}(s) Found </h6>").append(button)
      do Panel.init
      Panel.PanelBody.append(@head).append(@panel)
    removeDeco:->
      @deco.forEach (decoration)->
        try decoration.getMarker().destroy() catch
    clear:->
      @panel?.html ''
    destroy:->
      do @removeDeco
      @status = false
      @messages = []
      do @panel?.remove
      do @head?.remove
      do Panel.update
  UsagePanel = new PanelSection 'Usage','brown'
  ErrorPanel = new PanelSection 'Error','red'
  ReferenceMessage = class
    constructor:(@Message,@File,@Line,@Start,@End,@Trace = [])->
  PlainMessage = class
    constructor:(@Message)->
  return {ReferenceMessage,Panel,PlainMessage,UsagePanel,ErrorPanel}
