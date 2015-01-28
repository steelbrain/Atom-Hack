module.exports = (Main)->
  Instance = null
  Provider =
    selector: '.source.php,.source.cpp'
    requestHandler: (options) ->
      console.log options
      [{
        word: 'hello',
        prefix: 'h',
        label: '<span style="color: red">world</span>',
        renderLabelAsHtml: true,
        className: 'globe',
        onWillConfirm: -> # Do something here before the word has replaced the prefix (if you need, you usually don't need to),
        onDidConfirm: -> # Do something here after the word has replaced the prefix (if you need, you usually don't need to)
      }]
    dispose: ->
      # Your dispose logic here
  class AutoComplete
    @activate:->
      return if Main.Status.AutoComplete
      Instance = atom.services.provide('autocomplete.provider', '1.0.0', {provider:Provider})
      Main.Status.AutoComplete = true
    @deactivate:->
      return unless Main.Status.AutoComplete
      Instance.dispose()
      Main.Status.AutoComplete = false