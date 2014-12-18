AutoComplete = require "./autocomplete"

dis = module.exports =
  editorSubscription: null
  providers: []
  autocomplete: null
  activate: ->
    require('./linter')(dis)
  activateAutoComplete:->
    atom.packages.activatePackage("autocomplete-plus")
    .then (pkg) =>
      @autocomplete = pkg.mainModule
      @registerProviders()
  registerProviders: ->
    @editorSubscription = atom.workspace.observeTextEditors (editor) =>
      return unless editor?
      editorView = atom.views.getView(editor)
      if not editorView.mini
        provider = new AutoComplete(editor)
        @autocomplete.registerProviderForEditor(provider, editor)
        @providers.push provider
  deactivate: ->
    @editorSubscription?.dispose()
    @editorSubscription = null

    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider

    @providers = []