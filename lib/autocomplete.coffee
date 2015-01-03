require("string_score")
spawn = require('child_process').spawnSync
path = require 'path'

class HH
  @InstBlackList:[';','::','.','=','+','-','*','/','%']
  @append:(str,index,chr)->
    if index > str.length-1 then return str
    return str.substr(0,index)+chr+str.substr(index)
  @suggestions: (Buffer, Path,CursorPosition)->
    return spawn "hh_client",['--auto-complete'],cwd:path.dirname(Path),input:@append(Buffer.cachedText,Buffer.characterIndexForPosition(CursorPosition),'AUTO332')
  @filter:(values)->
    toReturn = []
    values.forEach (val)->
      if val isnt '' then toReturn.push(val)
    return toReturn
  @PreProcess:(Results)->
    ToReturn = []
    for Result in Results
      Result = Result.split(' ')
      ToReturn.push {label:Result.slice(1).join(' '),term:Result[0]}
    return ToReturn
  @SortResults:(Key,Results)->
    ToReturn = []
    for Result in Results
      Result.score = Result.term.score(Key)
      ToReturn.push Result
    ToReturn.sort (a,b)->
      return b.score-a.score
    return ToReturn
  @IsStatic:(Result,Editor)->
    return false if typeof Result[0] is 'undefined' or Result[0].term isnt 'class' or Result[0].label isnt 'string'
    return Editor.getBuffer().lineForRow(Editor.getCursorBufferPosition().row).split('::').splice(-1)[0]
  @IsInstance:(Result,Editor)->
    Buffer = Editor.getBuffer().lineForRow(Editor.getCursorBufferPosition().row).split('->');
    return false if Buffer.length is 1
    Buffer = Buffer.splice(-1)[0].split(';')[0]
    return false if Buffer.length is 0
    for word in @InstBlackList
      return false if Buffer.indexOf(word) isnt -1
    return Buffer
  @PostProcess:(Result,Editor)->
    Prefix = @IsStatic(Result,Editor) || @IsInstance(Result,Editor) || ''
    if Prefix isnt ''
      Result = @SortResults(Prefix,Result)
    return {Prefix:Prefix,Result:Result}
module.exports =
  ProviderClass:(Provider,Suggestion)->
    window.tmp = Suggestion
    class AutoComplete extends Provider
      exclusive: true
      buildSuggestions: ->
        editor = @editorView || @editor
        editorGrammar = editor.getGrammar().name
        if editorGrammar isnt 'PHP' and editorGrammar isnt 'C++' then return
        Result = HH.suggestions(editor.getBuffer(),editor.getPath(),editor.getCursorBufferPosition())
        return console.log("Unable to run HH_Client") if Result.error or Result.status
        {Prefix,Result} = HH.PostProcess(HH.PreProcess(HH.filter(Result.stdout.toString().split("\n"))),editor);
        toReturn = []
        for suggestion in Result
          toReturn.push new Suggestion(this, word: suggestion.term,prefix:Prefix, label: suggestion.label,data:body:suggestion.label)
        return toReturn