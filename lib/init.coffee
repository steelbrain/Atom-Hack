module.exports =
  config:
    enableTypeChecking:
      type: 'boolean'
      default: true
    interceptJumpToDeclarationCallsFor:
      type: 'array',
      default: ['C++','PHP']
      items:
        type: 'string'
    typeCheckerCommand:
      type: 'string'
      default: 'hh_client'
  Subscriptions:[]
  TypeCheckerDecorations:[]
  V:{}
  Status:{}
  activate:->
    @V.MP = require('atom-message-panel')
    @V.H = window.Atom_HACK_H = require('./h')(this)
    @V.TE = require('./typechecker-error')(this);
    @V.TTV = require('./tooltip-view')(this);

    require('./cmenu')(this).initialize();
    @V.MPI = new @V.MP.MessagePanelView title: "Hack TypeChecker"

    @Status.TypeChecker = false
    @V.H.readConfig().then =>
      setTimeout =>
        @V.TC = require('./typechecker')(this);
        atom.config.observe 'Atom-Hack.enableTypeChecking',(status)=>
          if status
            @V.TC.activate()
          else
            @V.TC.deactivate()
      ,500
  provide:->
    {providers: [require('./autocomplete')()]}
  deactivate:->
    @V.TC.deactivate();
    @Subscriptions.forEach (sub)-> sub.dispose()
    @Subscriptions = []