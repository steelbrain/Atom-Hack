path = require('path')
exec = require('child_process').exec
ssh = require('node-ssh')
Promise = require('bluebird')
fs = require 'fs'
class H
  constructor:(@Linter)->

  remotePath:(localPath)->
    localPath.replace(@Linter.config.localDir,@Linter.config.remoteDir).split(path.sep).join('/').replace(' ','\\ ')
  upload:(localPath)->
    remotePath = @remotePath(localPath)
    @Linter.ssh.put(localPath,remotePath)
  @readConfig:(path)->
    return new Promise (resolve,reject)->
      fs.exists path,(status)->
        if not status then return resolve(type:'local')
        fs.readFile path,'utf-8',(_,result)->
          try
            config = JSON.parse result
          catch error
            console.error error
            return reject("File #{path}")
          if typeof config.type is 'undefined' then config.type = 'local';
          if config.type is 'local' then return resolve(config)
          else if config.type isnt 'remote' then return reject("Invalid Type specified")
          config.localDir = config.localDir || atom.project.path
          config.remoteDir = config.remoteDir || atom.project.path
          config.port = config.port || 22
          config.autoPush = Boolean(config.autoPush) || false
          if typeof config.host is 'undefined'
            return reject("No remote host specified")
          else if typeof config.username is 'undefined'
            return reject("No username specified")
          else if typeof config.privateKey is 'undefined'
            return reject("No Private Key specified");
          fs.exists config.privateKey,(status)->
            if not status then reject("Specified Private Key doesn't exist")
            else resolve(config)
module.exports =
class Linter
  constructor:(onInit)->
    self = this
    @errors = [];
    @H = null;@config = null;@ssh = null
    @statusInit = 0 # 0 uninitialized, 1 for being, 2 for done
    @msgPanel = new (require './panel')(self)

    H.readConfig("#{atom.project.path}/.atom-hack").then (config)->
      self.config = config
      self.H = new H(self)
      if config.type is 'local' then return onInit(config)
      self.ssh = new ssh host: config.host,port: config.port,username: config.username,privateKey: config.privateKey
      self.ssh.connect().then ->
        console.debug "SSH Connection Stable"
        onInit(config)
    .catch (error)->
      self.config = type:'local'
      setTimeout (-> alert "Invalid Configuration #{error}"),500
      self.H = new H(self)
      onInit(self.config)

  init:->
    self = this
    atom.workspace.onDidChangeActivePaneItem ->
      self.msgPanel.render()
    atom.workspace.observeTextEditors (editor)->
      editor.buffer.onDidSave (info)->
        if self.config.type is 'remote' then self.H.upload(info.path).then(-> self.Lint(info.path)) else self.Lint(info.path)
  Lint:(localPath)->
    self = this
    if @config.type is 'local'
      dir = path.dirname(localPath).split(path.sep).join('/').replace(' ', '\\ ') #escaping spaces
      exec "hh_client --json --from atom", {"cwd": dir}, (_,__,errors)->
        self.setErrors(errors)
    else
      dir = @H.remotePath(path.dirname(localPath))
      @ssh.exec("hh_client --json --from atom", {"cwd": dir}).then (result)->
        self.setErrors(result.stderr)
  setErrors:(output)->
    self = this
    if output.substr(0,1) isnt '{'
      json = null
      response = output.split("\n")
      for chunk in response when chunk.substr(0,1) is '{' then json = chunk
      if json is null then return console.log("Invalid Response from HHClient") && console.debug(response)
      response = JSON.parse(json)
    else response = JSON.parse output
    @errors = []
    for error in response.errors
      deError = line: error.message[0].line,start: error.message[0].start, end: error.message[0].end, message:error.message[0].descr,file:error.message[0].path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep),trace:[]
      delete error.message[0]
      for trace in error.message when typeof trace isnt 'undefined'
        deError.trace.push line: trace.line,start: trace.start, end: trace.end, message:trace.descr,file:trace.path.replace(@config.remoteDir,@config.localDir).split('/').join(path.sep)
      @errors.push deError
    self.msgPanel.render()
