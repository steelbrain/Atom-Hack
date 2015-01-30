module.exports = (Main)->
  class CMenu
    @initialize:->
      Main.Subscriptions.push atom.commands.add 'atom-text-editor',
        'symbols-view:go-to-declaration': =>
          Editor = atom.workspace.getActiveEditor()
          return unless -1 isnt atom.config.get('Atom-Hack.interceptJumpToDeclarationCallsFor').indexOf(Editor.getGrammar().name)

          Buffer = Editor.getBuffer()
          Path = Editor.getPath()
          Position = Editor.getCursorBufferPosition()
          Main.V.H.exec(['--identify-function',(Position.row+1)+':'+(Position.column+1)],Buffer.cachedText,Path).then (result)->
            output = result.stdout.trim()
            return unless output.length
            Main.V.H.exec(['--search',output,'--json'],Buffer.cachedText,Path).then (result)->
              result = JSON.parse(result.stdout)
              return unless result.length
              atom.workspace.open(result[0].filename).then ->
                atom.workspace.getActiveEditor().setCursorBufferPosition [result[0].line-1,result[0].char_start-1]