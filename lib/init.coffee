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
    @V.TC = require('./typechecker')(this);
    @V.TE = require('./typechecker-error')(this);
    @V.TTV = require('./tooltip-view')(this);
    @V.TT = require('./tooltip')(this);

    console.log "Initializing Atom-Hack"
    require('./cmenu')(this).initialize();
    @V.TT.activate();
    @V.MPI = new @V.MP.MessagePanelView title: "Hack TypeChecker"

    @Status.TypeChecker = false
    @V.H.readConfig().then =>
      atom.config.observe 'Atom-Hack.enableTypeChecking',(status)=>
        if status
          @V.TC.activate()
        else
          @V.TC.deactivate()
  provide:->
    {providers: [require('./autocomplete')()]}
  deactivate:->
    @V.TC.deactivate();
    @V.TT.deactivate();
    @Subscriptions.forEach (sub)-> sub.dispose()
    @Subscriptions = []