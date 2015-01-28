module.exports = (Main)->
  class H
    @configDefault: type:'local'
    @config: @configDefault
    @readConfig:->
      return new Promise (resolve,reject)=>
        configPath = atom.project.path + '/.atom-hack'
        Main.V.FS.exists configPath,(exists)=>
          return resolve() unless exists
          Main.V.FS.readFile configPath,(_,config)=>
            try
              config = JSON.parse(config)
            catch
              alert "Invalid JSON in Atom-Hack configuration File"
              return resolve()
            config.type = config.type || 'local'
            @config = config
            resolve()
    @spawn:->
      @exec([],null,atom.project.path);
    @exec:(args,input,path)->
      toReturn = stderr:'',stdout:''
      command = atom.config.get('Atom-Hack.typeCheckerCommand')
      return new Promise (resolve)=>
        Proc = Main.V.CP.spawn command,args,{cwd:Main.V.Path.dirname(path)}
        if input and input.length
          Proc.stdin.write input
        Proc.stdin.end()
        Proc.stdout.on 'data',(data)=>
          toReturn.stdout += data
        Proc.stderr.on 'data',(data)=>
          toReturn.stderr += data
        Proc.on 'exit',=>
          resolve toReturn