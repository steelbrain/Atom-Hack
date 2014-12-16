path = require('path')
exec = require('child_process').exec
ssh_connect = require('ssh2-connect')
ssh_exec = require('ssh2-exec')
Promise = require('bluebird')
msgPanel = require('atom-message-panel')
fs = require('fs')
class Linter
  constructor:->
    @config = {}
    @errors = []
    @decorations = []
    @status = 0 # 0 for uninitialized, 1 for being initialized, anything else for done
    @msgPanel = 0
    @promise = null
    @ssh_conn = null
    me = this
    atom.workspace.onDidChangeActivePaneItem ->
      if me.errors.length isnt 0
        me.markClear()
        me.markErrors()
      return
    atom.workspace.observePaneItems (pane)->
      if typeof pane.onDidDestroy is 'undefined' then return
      pane.onDidDestroy ->
        if me.errors.length isnt 0
          me.markClear()
          me.markErrors()
        return
      return
    atom.workspace.observeTextEditors (editor)->
      if not( editor.getGrammar().name is 'PHP' or editor.getGrammar().name is 'C++' or '<?hh' is editor.buffer.cachedText.substr(0,4) or '<?php' is editor.buffer.cachedText.substr(0,5) )
        return
      editor.buffer.onDidSave (info)->
        if me.status is 0
          me.promise = me.init().then ->
            me.status = 2
            me.promise = null
            if me.config.type is 'local'
              me.lintLocal info.path
            else
              me.lintRemote info.path
            return
        else if me.status is 1
          me.promise().then ->
            if me.config.type is 'local'
              me.lintLocal info.path
            else
              me.lintRemote info.path
            return
        else
          if me.config.type is 'local'
            me.lintLocal info.path
          else
            me.lintRemote info.path
        return
      return
  lintLocal: (file)->
    me = this
    dir = path.dirname(file).replace(' ', '\\ ') #escaping spaces
    exec "hh_client --json --from atom #{dir}",(_,__,response)->
      me.handleResponse response
      return
    return
  lintRemote: (file)->
    me = this
    dir = path.dirname(file).replace(@config.localDir,@config.remoteDir)
    ssh_exec {cmd:"hh_server --json --check #{dir}",ssh:@ssh_conn},(_,__,response)->
      me.handleResponse response
      return
    return
  handleResponse: (response)->
    if response.substr(0,1) isnt '{'
      # new hh_server has been started, filter the un-needed stuff
      json = null
      response = response.split("\n")
      for chunk in response when chunk.substr(0,1) is '{'
        json = chunk
      if json is null
        console.log "Invalid Response from HHClient"
        console.debug response
        return
      else
        response = JSON.parse(json)
    else
      response = JSON.parse response
    @markClear()
    if response.passed
      @markRemove()
      return
    @errors = []
    for error in response.errors
      dis = line: error.message[0].line,start: error.message[0].start, end: error.message[0].end, message:error.message[0].descr,file:error.message[0].path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep),trace:[]
      delete error.message[0]
      for trace in error.message when typeof trace isnt 'undefined'
        dis.trace.push line: trace.line,start: trace.start, end: trace.end, message:trace.descr,file:trace.path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep)
      @errors.push dis
    if atom.workspaceView.find('.am-panel').length isnt 1
      msgPanel.init('<span class="icon-bug"></span> Hack report')
      @msgPanel = 1
    @markErrors()
    return
  markRemove:->
    @msgPanel = 0
    msgPanel.destroy()
    return
  markClear:->
    # Remove HighLights
    @decorations.forEach (v)->
      v.getMarker().destroy()
      return
    msgPanel.clear()
    return
  markErrors: ->
    editors = {};
    editors_atom = atom.workspace.getEditors()
    active_editor = atom.workspace.getActiveEditor();
    if typeof active_editor is 'undefined'
      @markRemove()
      return
    @decorations = []
    for editor in editors_atom
      editors[editor.getPath()] = editor
    for error in @errors
      if typeof editors[error.file] isnt 'undefined'
        editor = editors[error.file]
        if error.start is error.end then error.end++
        range = [[error.line-1,error.start-1],[error.line-1,error.end]]
        marker = editor.markBufferRange(range, {invalidate: 'never'})
        @decorations.push editor.decorateMarker(marker, {type: "highlight", class: "highlight-red"})
        @decorations.push editor.decorateMarker(marker, {type: "gutter", class: "gutter-red"})
        for entry in error.trace
          if typeof editors[entry.file] isnt 'undefined'
            if entry.start is entry.end then entry.end++
            range = [[entry.line-1,entry.start-1],[entry.line-1,entry.end]]
            marker = editors[entry.file].markBufferRange(range, {invalidate: 'never'})
            @decorations.push editors[entry.file].decorateMarker(marker, {type: "highlight", class: "highlight-blue"})
            @decorations.push editors[entry.file].decorateMarker(marker, {type: "gutter", class: "gutter-blue"})

    currentFile = active_editor.getPath()
    for error in @errors
      if currentFile isnt error.file
        msgPanel.append.message @stringify(error),'text-warning'
      else
        trace = []
        for entry in error.trace
          trace.push @stringify entry
        msgPanel.append.lineMessage error.line,error.start,error.message,trace.join("\n"),'text-warning'
    return
  stringify:(error)->
    "#{error.message} at Line #{error.line} Col #{error.start} in #{error.file}"
  init:->
    me = this
    return new Promise (resolve)->
      if fs.existsSync "#{atom.project.path}/.atom-hack"
        fs.readFile "#{atom.project.path}/.atom-hack",'utf-8',(_,result)->
          config = JSON.parse(result)
          if typeof config.type is 'undefined' then config.type = 'local'
          if typeof config.port is 'undefined' then config.port = 'local'
          if typeof config.localDir is 'undefined' then config.localDir = atom.project.path
          if typeof config.remoteDir is 'undefined' then config.remoteDir = atom.project.path
          if config.type is 'remote'
            ssh_connect host:config.host,port:config.port,username:config.username,privateKeyPath:config.privateKeyPath,(err,ssh)->
              if (typeof ssh == 'undefined')
                console.log("Error establishing SSH Connection.")
              else
                console.log "SSH Connection Stable"
                me.ssh_conn = ssh;
              resolve()
          else
            resolve()
          return
      else
        me.config =
          type: 'local',
          localDir: atom.project.path
          remoteDir: atom.project.path
        resolve()
      return
  startsWith:(str,match)->
    return 0 is str.indexOf match
module.exports = ->
  new Linter()
