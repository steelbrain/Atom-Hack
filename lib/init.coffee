# AutoComplete = require "./autocomplete"
Linter = require './linter'

dis = module.exports =
  editorSubscription: null
  providers: []
  autocomplete: null
  activate: ->
    new Linter(dis)
  activateAutoComplete:->
    return
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
    return
    @editorSubscription?.dispose()
    @editorSubscription = null

    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider

    @providers = []
