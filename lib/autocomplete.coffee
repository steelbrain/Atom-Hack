require 'string_score'
module.exports = ->
  Provider =
    exclusive: true
    selector: '.source.php,.source.cpp,.source.hack'
    blacklist: '.comment'
    requestHandler:(options)->
      AutoComplete.suggestions(options.buffer,options.editor)
  class AutoComplete
    @points = ['"',"'",' ',')','(',',','{','}','-','+','>','<',';',"\n","\r"]
    @suggestions:(buffer,editor)->
      path = editor.getPath()
      text = buffer.getText()
      index = buffer.characterIndexForPosition(editor.getCursorBufferPosition())
      text = text.substr(0,index)+'AUTO332'+text.substr(index)
      prefix = @prefix(text,index)
      return new Promise (resolve)->
        window.Atom_HACK_H.exec(['--auto-complete'],text,path).then (result)->
          toReturn = []
          result = result.stdout.split("\n").filter((e)-> e)
          score = prefix.length > 0
          if result.length
            result.forEach (entry)->
              entry = entry.split(' ')
              toReturn.push {word:entry[0],label:entry.slice(1).join(' '),prefix:prefix,score:(score and entry[0].score(prefix))}
            toReturn.sort (a,b)=>
              b.score - a.score
          resolve toReturn
    @prefix:(text,index)->
      LaText = []
      while((index = index-1))
        char = text.substr(index,1)
        if @points.indexOf(char) isnt -1
          break
        LaText.push char
      LaText = LaText.reverse().join('').split('::')
      return LaText[LaText.length-1].trim();
  return Provider