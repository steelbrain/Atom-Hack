module.exports =
  activate: ->
    try
      require('./linter')()
    catch err
      console.log err