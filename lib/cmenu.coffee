spawn = require('child_process').spawnSync
spawnAsync = require('child_process').spawn
path = require 'path'

module.exports = (Main)->
  @usageInit = =>
    atom.contextMenu.add {
      'atom-workspace': [{label: 'Find Usages', command: 'atom-hack:find-usage'}]
      'atom-text-editor': [{
        label: 'Find Usages',
        command:'atom-hack:find-usage'
      }]
    }
    Main.Offable.push atom.workspaceView.on 'atom-hack:find-usage',=>
      editor = atom.workspace.getActiveEditor()
      editorGrammar = editor.getGrammar().name
      return unless editorGrammar is 'C++' or editorGrammar is 'PHP'
      @usages editor
    Main.Disposables.push atom.commands.add 'atom-text-editor',
      'symbols-view:go-to-declaration': =>
        editor = atom.workspace.getActiveEditor()
        editorGrammar = editor.getGrammar().name
        return unless editorGrammar is 'C++' or editorGrammar is 'PHP'
        @declaration editor
  @search = (editor)=>
    Buffer = editor.getBuffer()
    Position = editor.getCursorBufferPosition()
    ProjectPath = Main.getProjectRoot()
    result = spawn "hh_client",['--identify-function',(Position.row+1)+':'+(Position.column+1)],{cwd:ProjectPath,input:Buffer.cachedText}
    .stdout.toString().trim()
    throw null if result.length is 0 or result.substr(0,1) is '$'
    DeResult = JSON.parse( spawn "hh_client",['--search',result,'--json'],{cwd:ProjectPath,input:Buffer.cachedText}
    .stdout.toString().trim() )
    throw null if DeResult.length < 1
    return DeResult
  @usages = (editor)=>
    try
      Buffer = editor.getBuffer()
      Result = @search(editor)[0]
      if Result.desc is 'function'
        Results = JSON.parse(spawn "hh_client",['--find-refs',Result.name,'--json'],{cwd:Main.getProjectRoot(),input:Buffer.cachedText}
                  .stdout.toString())
      else if Result.desc is 'class'
        Results = JSON.parse(spawn "hh_client",['--find-class-refs',Result.name,'--json'],{cwd:Main.getProjectRoot(),input:Buffer.cachedText}
        .stdout.toString())
      else
        console.log Result
        return
    catch error
      return console.error error
    Messages = [];
    Results.forEach (result)->
      if typeof result.scope is 'undefined' || result.scope.length is 0
        Messages.push new Main.Panel.ReferenceMessage result.name,result.filename,result.line,result.char_start,result.char_end
      else
        Messages.push new Main.Panel.ReferenceMessage result.scope+'::'+result.name,result.filename,result.line,result.char_start,result.char_end
    try
      Main.Panel.UsagePanel.add Messages
    catch error
      console.log error
  @declaration = (editor)=>
    try
      Result = @search(editor)[0]
    catch then return
    Main.openFile(Result.filename,Result.line,Result.char_start)
  this