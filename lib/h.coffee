module.exports = (Main)->
  FS = require('fs')
  Path = require('path')
  SSH = require('node-ssh')
  ChildProcess = require('child_process')
  class H
    @configDefault: type:'local'
    @config: @configDefault
    @SSH: null
    @readConfig:->
      return new Promise (resolve)=>
        configPath = atom.project.getPath() + '/.atom-hack'
        FS.exists configPath,(exists)=>
          return resolve() unless exists
          FS.readFile configPath,(_,config)=>
            try
              config = JSON.parse(config)
            catch
              alert "Invalid JSON in Atom-Hack configuration File"
              return resolve()
            config.type = config.type || 'local'
            @config = config
            if config.type is 'remote'
              @SSH = new SSH(config)
              @SSH.connect().then ->
                resolve()
            else
              resolve()
    @execRemote:(args,input,path)->
      toReturn = stderr:'',stdout:''
      RemotePath = path.replace(atom.project.getPath(),@config.remoteDir).split(Path.sep).join('/')
      command = atom.config.get('Atom-Hack.typeCheckerCommand')
      if input and input.length
        return Promise.resolve(toReturn)
      return new Promise (resolve)=>
        if @config.autoPush
          LePromise = @SSH.put(path,RemotePath)
        else
          LePromise = Promise.resolve()
        LePromise.then =>
          @SSH.exec(command+' '+args.join(' '),{cwd:RemotePath.split('/').slice(0,-1).join('/')}).then (result)->
            resolve(result)
    @execLocal:(args,input,path)->
      toReturn = stderr:'',stdout:''
      command = atom.config.get('Atom-Hack.typeCheckerCommand')
      return new Promise (resolve)=>
        Proc = ChildProcess.spawn command,args,{cwd:Path.dirname(path)}
        if input and input.length
          Proc.stdin.write input
        Proc.stdin.end()
        Proc.stdout.on 'data',(data)=>
          toReturn.stdout += data
        Proc.stderr.on 'data',(data)=>
          toReturn.stderr += data
        Proc.on 'close',=>
          resolve toReturn
    @exec:(args,input,path)->
      if @config.type is 'local'
        return @execLocal(args,input,path)
      else
        return @execRemote(args,input,path)
