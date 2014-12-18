{Provider, Suggestion} = require "autocomplete-plus"
spawn = require('child_process').spawnSync
path = require 'path'

appendAtPoint = (str,index,chr)->
  if index > str.length-1 then return str
  return str.substr(0,index)+chr+str.substr(index)
module.exports =
  class AutoComplete extends Provider
    wordRegex: /[a-zA-Z0-9\.\/_-]*\/[a-zA-Z0-9\.\/_-]*/g
    exclusive: true
    buildSuggestions: ->
      editorGrammar = @editorView.getGrammar().name
      if editorGrammar isnt 'PHP' and editorGrammar isnt 'C++' then return
      buffer = @editorView.getBuffer()
      result = spawn "hh_client", ["--auto-complete"],cwd: path.dirname(@editorView.getPath()),input:appendAtPoint(buffer.cachedText,buffer.characterIndexForPosition(@editorView.getCursorBufferPosition()),'AUTO332')
      if result.error or result.status
        console.log "Unable to run hh_client"
      result = result.stdout.toString().split("\n")
      suggestions = []
      for suggestion in result when suggestion.length > 0
        suggestions.push new Suggestion(this, word: (suggestion.split(' ')[0]),prefix:'', label: suggestion)
      if suggestions.length < 1
        return
      return suggestions