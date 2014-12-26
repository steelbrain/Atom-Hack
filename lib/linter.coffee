path = require('path')
exec = require('child_process').exec
ssh = require('node-ssh')
Promise = require('bluebird')
msgPanel = new (require('./panel'))('<span class="icon-bug"></span> Hack report')
fs = require('fs')
{$} = require('atom')
class Linter
  constructor:(@main)->
    self = this
    @config = {type:"local"}
    @errors = []
    @decorations = []
    @statusInit = 0 # 0 uninitialized, 1 for being, 2 for done
    @ssh = null
    # read config, then onInit
    setTimeout ->
      self.readConfig().then (config)->
        self.config = config
        self.onInit()
        main.activateAutoComplete()
    ,500
  readConfig:->
    self = this
    return new Promise (resolve)->
      console.log "#{atom.project.path}/.atom-hack"
      if fs.existsSync "#{atom.project.path}/.atom-hack"
        fs.readFile "#{atom.project.path}/.atom-hack",'utf-8',(_,result)->
          config = JSON.parse(result)
          if typeof config.type is 'undefined' then config.type = 'local'
          if typeof config.port is 'undefined' then config.port = 'local'
          if typeof config.localDir is 'undefined' then config.localDir = atom.project.path
          if typeof config.remoteDir is 'undefined' then config.remoteDir = atom.project.path
          if config.type is 'local'
            resolve(config)
          else
            self.ssh = new ssh({
              host: config.host,
              port: config.port,
              username: config.username,
              privateKey: config.privateKey
            })
            self.ssh.connect().then ->
              console.debug "SSH Connection Stable"
              resolve(config)
      else
        resolve({type:'local'})
  onInit:->
    self = this
    atom.workspace.onDidChangeActivePaneItem ->
      self.redraw()
    atom.workspace.observePaneItems (pane)->
      if typeof pane.onDidDestroy is 'undefined' then return
      pane.onDidDestroy ->
        self.redraw()
    atom.workspace.observeTextEditors (editor)->
      grammar = editor.getGrammar()
      editor.buffer.onDidSave (info)->
        if self.config.type is 'remote'
          self.deployRemote(info.path).then ->
            console.log "it's been saved"
            self.onSave(info.path)
        else
          self.onSave(info.path)
  deployRemote:(localPath)->
    remotePath = localPath.replace(@config.localDir,@config.remoteDir).split('\\').join(path.sep).replace(' ','\\ ')
    return @ssh.put(localPath,remotePath)
  onSave:(localPath)->
    self = this
    if @config.type is 'local'
      dir = path.dirname(localPath).replace(' ', '\\ ') #escaping spaces
      exec "hh_client --json --from atom #{localPath}",(_,__,stderr)->
        self.setErrors(stderr)
        self.redraw()
    else if @config.type is 'remote'
      dir = path.dirname(localPath).replace(@config.localDir,@config.remoteDir).split('\\').join(path.sep).replace(' ','\\ ')
      @ssh.exec("hh_client --json --from atom #{dir}").then (result)->
        self.setErrors(result.stderr)
        self.redraw()
  setErrors:(output)->
    self = this
    if output.substr(0,1) isnt '{'
      json = null
      response = output.split("\n")
      for chunk in response when chunk.substr(0,1) is '{'
        json = chunk
      if json is null
        console.log "Invalid Response from HHClient"
        console.debug response
        return
      response = JSON.parse(json)
    else
      response = JSON.parse output
    @errors = []
    for error in response.errors
      dis = line: error.message[0].line,start: error.message[0].start, end: error.message[0].end, message:error.message[0].descr,file:error.message[0].path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep),trace:[]
      delete error.message[0]
      for trace in error.message when typeof trace isnt 'undefined'
        dis.trace.push line: trace.line,start: trace.start, end: trace.end, message:trace.descr,file:trace.path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep)
      if @errors.indexOf dis is -1
        @errors.push dis
  redraw:->
    @decorations.forEach (v)->
      try
        v.getMarker().destroy()
      catch
    @decorations = []
    if msgPanel.status is 1
      # started
      if @errors.length < 1
        msgPanel.destroy()
        return
      msgPanel.clear()
    else
      # not yet started
      if @errors.length < 1
        msgPanel.destroy()
        return
    # Time to Mark Em, Eh!
    editors = []
    editors_atom = atom.workspace.getEditors()
    active_file = atom.workspace.getActiveEditor().getPath()
    for editor in editors_atom
      editors[editor.getPath()] = editor
    # Add the decorations first
    for error in @errors
      if typeof editors[error.file] isnt 'undefined'
        editor = editors[error.file]
        if error.start is error.end then error.end++
        range = [[error.line-1,error.start-1],[error.line-1,error.end]]
        marker = editor.markBufferRange(range, {invalidate: 'never'})
        @decorations.push editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-red'})
        @decorations.push editor.decorateMarker(marker, {type: 'gutter', class: 'gutter-red'})
        for entry in error.trace
          if typeof editors[entry.file] isnt 'undefined'
            if entry.start is entry.end then entry.end++
            range = [[entry.line-1,entry.start-1],[entry.line-1,entry.end]]
            marker = editors[entry.file].markBufferRange(range, {invalidate: 'never'})
            @decorations.push editors[entry.file].decorateMarker(marker, {type: 'highlight', class: 'highlight-blue'})
            @decorations.push editors[entry.file].decorateMarker(marker, {type: 'gutter', class: 'gutter-blue'})
    errorsSelf = []
    errorsOthers = []
    for error in @errors
      file = error.file
      if active_file is file
        errorsSelf.push error
      else
        errorsOthers.push error
    for error in errorsSelf
      msgPanel.appendPointer error,active_file
    for error in errorsOthers
      file = error[1]
      msgPanel.otherFile error,'text-warning'
module.exports = Linter