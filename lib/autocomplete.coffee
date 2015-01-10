require("string_score")
spawn = require('child_process').spawnSync
path = require 'path'


class HH
  @PresurePoints = ['"',"'",' ',';','::','.','=','+','-','*','/','%','>','<']
  @Append:(str,index,chr)->
    if index > str.length-1 then return str
    return str.substr(0,index)+chr+str.substr(index)
  @GetSuggestions: (Buffer, Path,CursorPosition)->
    return spawn "hh_client",['--auto-complete'],cwd:path.dirname(Path),input:@Append(Buffer.cachedText,Buffer.characterIndexForPosition(CursorPosition),'AUTO332')
  @PostProcess:(Term,Values)->
    toReturn = []
    if Term is null
      Values.forEach (val)->
        return if val is ''
        val = val.split(' ')
        toReturn.push label:val.slice(1).join(' '),term:val[0]
    else
      Values.forEach (val)->
        return if val is ''
        val = val.split(' ')
        toReturn.push label:val.slice(1).join(' '),term:val[0],score:val[0].score(Term)
      toReturn.sort (a,b)->
        return b.score-a.score
    return toReturn;
  @Suggest:(Results,Editor)->
    CurrentLine = Editor.getBuffer().lineForRow(Editor.getCursorBufferPosition().row)
    return CurrentLine.split('::').splice(-1)[0] if Results[0] is 'class string'
    Inst = CurrentLine.split('->')
    return Inst.splice(-1)[0] if Inst.length > 1
    return CurrentLine.split('=').splice(-1)[0]
  @Process:(Results,Editor)->
    Prefix = @Suggest(Results,Editor)
    if Prefix isnt null
      Prefix = Prefix.trim()
      I = 0
      Chunks = Prefix.split('')
      for Chunk of Chunks
        break if(@PresurePoints.indexOf(Chunk) isnt -1)
        ++I;
      if I is 0 then Prefix = null
      else Prefix = Prefix.substr(0,I)
    Results = @PostProcess(Prefix,Results)
    return {Prefix:Prefix,Result:Results}
module.exports =
  ProviderClass:(Provider,Suggestion,Main)->
    class AutoComplete extends Provider
      exclusive: true
      buildSuggestions: ->
        editor = @editorView || @editor
        editorGrammar = editor.getGrammar().name
        if editorGrammar isnt 'PHP' and editorGrammar isnt 'C++' then return
        Result = HH.GetSuggestions(editor.getBuffer(),Main.getPath(editor.getPath()),editor.getCursorBufferPosition())
        return console.log("Unable to run HH_Client",Result.error,Result.status) if Result.error or Result.status
        {Prefix,Result} = HH.Process(Result.stdout.toString().split("\n"),editor)
        toReturn = []
        for suggestion in Result
          toReturn.push new Suggestion(this, word: suggestion.term,prefix:Prefix, label: suggestion.label,data:body:suggestion.label)
        return toReturn
