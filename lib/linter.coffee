path = require('path')
exec = require('child_process').exec
ssh = require('node-ssh')
Promise = require('bluebird')
fs = require 'fs'

module.exports =
  class Linter
    constructor:(@Main)->
      @ssh = null
      if @Main.Config.type is 'remote'
        @ssh = new ssh host: Main.Config.host,port: Main.Config.port,username: Main.Config.username,privateKey: Main.Config.privateKey
        @ssh.connect().then ->
          console.debug "SSH Connection Stable"
      Main.Disposables.push atom.workspace.observeTextEditors (editor)=>
        editor.buffer.onDidSave (info)=>
          @Lint(info)

    Lint:(localPath)->
      if @Main.Config.type is 'local'
        exec "hh_client --json --from atom", {"cwd": @Main.getPath(localPath.path)}, (_,__,errors)=>
          @setErrors(errors)
      else
        if @Main.Config.autoPush
          @ssh.put(localPath,@Main.getPath(localPath.path)).then =>
            @ssh.exec("hh_client --json --from atom", {"cwd": @Main.getProjectRoot()}).then (result) =>
              @setErrors(result.stderr)
        else
          exec "hh_client --json --from atom", {"cwd": @Main.getProjectRoot()},(_,__,result)=>
            @setErrors(result)
    setErrors:(output)->
      self = this
      if output.substr(0,1) isnt '{'
        json = null
        response = output.split("\n")
        for chunk in response when chunk.substr(0,1) is '{' then json = chunk
        if json is null then return console.log("Invalid Response from HHClient") && console.debug(response)
        response = JSON.parse(json)
      else response = JSON.parse output
      errors = []
      for error in response.errors
        Errors = []
        for entry in error.message
          Errors.push new @Main.Panel.ReferenceMessage entry.descr,entry.path,entry.line,entry.start,entry.end
        DeError = Errors[0]
        DeError.Trace = Errors.splice(1)
        errors.push DeError
      try
        @Main.Panel.ErrorPanel.add errors
      catch error
        console.log error
