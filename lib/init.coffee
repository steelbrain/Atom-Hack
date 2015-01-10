Promise = null
FS = null
Path = null
Tooltip = null
CMenu = null


module.exports =
  Providers:[]
  config: {}
  Config:null
  DefaultConfig:{type:"local"}
  Subscriptions:[]
  Disposables:[]
  Offable:[] # Offable,I like that name :laughing:
  AutoComplete:null
  activate:->
    Promise = require('bluebird');
    FS = require('fs')
    Path = require('path')
    Tooltip = require('./tooltip')
    CMenu = require('./cmenu')(this)
    @Panel = require('./panel')(this)

    @config().then =>
      new (require('./linter'))(this)
      if @Config.type is 'local' or @Config.isLAN
        # Init AutoComplete
        atom.packages.activatePackage("autocomplete-plus").then (pkg)=>
          @AutoComplete = pkg.mainModule
          return unless @AutoComplete?
          Provider = (require './autocomplete').ProviderClass(@AutoComplete.Provider, @AutoComplete.Suggestion,this)
          return unless Provider?
          try
            @Subscriptions.push atom.workspace.observeTextEditors((editor) => @registerProvider(Provider, editor))
          catch error
            console.error error
        # Init Tooltips
        @Offable.push atom.workspaceView.eachEditorView (editorView) =>
          editor = editorView.getEditor()
          editorGrammar = editor.getGrammar().name
          return unless editorGrammar is 'C++' or editorGrammar is 'PHP'
          new Tooltip editorView,editor,this
        # Init ContextMenus
        do CMenu.usageInit
# Init Linter
  config:->
    return new Promise (resolve)=>
      setTimeout =>
        filePath = atom.project.path+'/.atom-hack'
        FS.exists filePath,(status)=>
          return resolve(@Config = @DefaultConfig) if not status
          FS.readFile filePath,(_,config)=>
            try
              config = JSON.parse(config.toString())
            catch error
              alert("Invalid Configuration, Parse Error: #{error.message}")
              return resolve(@Config = @DefaultConfig)
            config.type = config.type || 'local'
            return resolve(@Config = @DefaultConfig) if config.type is 'local'
            config.port = config.port || 22
            config.localDir = config.localDir || atom.project.path
            config.remoteDir = config.remoteDir || atom.project.path
            config.autoPush = Boolean(config.autoPush) || false
            config.isLAN = Boolean(config.isLAN) || false
            resolve(@Config = config);
      ,1500 # wait for open-last-project package
  registerProvider: (Provider, editor)->
    return unless Provider?
    return unless editor?
    editorView = atom.views.getView(editor)
    return unless editorView?
    return if editorView.mini
    provider = new Provider(editor)
    @AutoComplete.registerProviderForEditor(provider, editor)
    @Providers.push(provider)
  getPath:(filePath)->
    if @Config.type is 'remote'
      Path.dirname filePath.replace(@Config.localDir,@Config.remoteDir).split(Path.sep).join('/').replace(' ','\\ ')
    else
      Path.dirname filePath.split(Path.sep).join('/').replace(' ','\\ ')
  getProjectRoot:->
    if @Config.type is 'remote'
      return @Config.remoteDir
    else
      return atom.project.path
  openFile:(Path,Line,Char)->
    atom.workspace.open Path #char_start,char_end,line
    setTimeout =>
      editor = null
      atom.workspace.getEditors().forEach (DeEditor)=>
        if DeEditor.getPath() is Path
          editor = DeEditor
      editor.setCursorBufferPosition [Line-1,Char-1]
    ,500
  deactivate:->
    @Subscriptions.forEach (sub) => do sub?.dispose
    @Providers.forEach (provider) => @AutoComplete.unregisterProvider(provider)
    @Disposables.forEach (disposable) => do disposable.dispose
    @Offable.forEach (offable) => do offable.off
    @Subscriptions = []
    @Providers = []
    @Disposables = []
    @Offable = []