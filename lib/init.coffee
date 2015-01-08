self = module.exports =
  editorSubscription: null
  providers: []
  autocomplete: null
  activate: ->
    setTimeout ->
      Linter = require './linter'
      Linter = new Linter (config)->
        Linter.init()
        return unless config.type is 'local'
        atom.workspaceView.eachEditorView (editorView) =>
          new ToolTip(editorView)
        atom.packages.activatePackage("autocomplete-plus")
        .then (pkg) =>
          self.autocomplete = pkg.mainModule
          return unless self.autocomplete?
          Provider = (require './autocomplete').ProviderClass(self.autocomplete.Provider, self.autocomplete.Suggestion)
          return unless Provider?
          try
            self.editorSubscription = atom.workspace.observeTextEditors((editor) => self.registerProvider(Provider, editor))
          catch error
            console.error error
    ,2000
  registerProvider: (Provider, editor)->
    return unless Provider?
    return unless editor?
    editorView = atom.views.getView(editor)
    return unless editorView?
    return if editorView.mini
    provider = new Provider(editor)
    self.autocomplete.registerProviderForEditor(provider, editor)
    self.providers.push(provider)
  deactivate: ->
    self.editorSubscription?.selfpose()
    self.editorSubscription = null
    self.providers.forEach (provider) =>
      self.autocomplete.unregisterProvider provider
    self.providers = []
