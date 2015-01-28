module.exports = (Main)->
  class AutoComplete
    @activate:->
      console.log "AutoComplete Activate"
    @deactivate:->
      console.log "AutoComplete DeActivate"