"use strict";
var path = require('path'),
    msgPanel = require('atom-message-panel'),
    exec = require('child_process').exec,
    Promise = require('bluebird'),
    editor,
    ssh_connect = require('ssh2-connect'),
    ssh_exec = require('ssh2-exec'),
    ssh_conn;
module.exports = new function(){
  var me = this,
      handle_local = function(){
        if(!validate())
          return;
        var dir = my_dir();
        exec('hh_client --json --from atom "'+dir+'"',function(_,__,response){
          error_handle(response);
        });
      },
      handle_remote = function(){
        if(!validate())
          return;
        var dir = my_dir().replace(atom.project.path,me.config.remoteDir).replace(path.sep,'/');
        ssh_exec({cmd:'hh_client --from atom --json "'+dir+'"',ssh:ssh_conn},function(error,stdout,stderr){
          error_handle(stderr);
        });
      },
      error_handle = function(stderr){
        try {
          var output = JSON.parse(stderr);
          if(output.passed){
            msgPanel.destroy();
          } else {
            var errors = [];
            for(var i in output.errors){
              if(output.errors.hasOwnProperty(i)){
                var error = {
                  'code' : output.errors[i]['message'][0]['code'],
                  'message' : output.errors[i]['message'][0]['descr'],
                  'char_start' : output.errors[i]['message'][0]['start'],
                  'char_end' : output.errors[i]['message'][0]['end'],
                  'line' : output.errors[i]['message'][0]['line'],
                  'file' : output.errors[i]['message'][0]['path'].replace(me.config.remoteDir,atom.project.path).replace('/',path.sep),
                  'trace' : []
                };
                delete output.errors[i]['message'][0];
                for(var ii in output.errors[i]['message']){
                  if(output.errors[i]['message'].hasOwnProperty(ii)){
                    error.trace.push({
                      'code' : output.errors[i]['message'][ii]['code'],
                      'message' : output.errors[i]['message'][ii]['descr'],
                      'char_start' : output.errors[i]['message'][ii]['start'],
                      'char_end' : output.errors[i]['message'][ii]['end'],
                      'line' : output.errors[i]['message'][ii]['line'],
                      'file' : output.errors[i]['message'][ii]['path'].replace(me.config.remoteDir,atom.project.path).replace('/',path.sep)
                    });
                  }
                }
                errors.push(error);
              }
            }
            error_multiple(errors);
          }
        } catch(err){
          error_single(stderr);
        }
      },
      error_pre = function(){
        if (atom.workspaceView.find('.am-panel').length !== 1) {
          msgPanel.init('<span class="icon-bug"></span> Hack report');
        } else {
          msgPanel.clear();
        }
      },
      error_post = function(){
        atom.workspaceView.on('pane-container:active-pane-item-changed destroyed', function () {
          msgPanel.destroy();
        });
      },
      error_single = function(message){
        error_pre();
        msgPanel.append.message(message, 'text-warning');
        error_post();
      },
      error_multiple = function(errors){
        error_pre();
        var current_file = editor.getPath(),lines = [];
        for(var i in errors){
          if(errors.hasOwnProperty(i)){
            if(errors[i].file === current_file){
              msgPanel.append.lineMessage(errors[i].line, errors[i].char_start, errors[i].message, errors[i]['trace'].join("\n"), 'text-warning');
            } else {
              msgPanel.append.message(errors[i].message+' @Line# '+errors[i].line+' Col '+errors[i].char_start+' in file '+errors[i].file, 'text-warning');
            }
          }
        }
        error_post();
      },
      validate = function(){
        editor = atom.workspace.getActiveEditor();
        return !!editor && editor.getGrammar().name === me.config.grammar;
      },
      my_dir = function(){
        return path.dirname(editor.getPath()).replace('"','\"');
      },
      init_remote = function(){
        var config = {
            host:me.config.host,
            port:me.config.port,
            username:me.config.username,
            privateKeyPath: me.config.privateKey
        };
        ssh_connect(config,function(err,ssh){
          if(typeof ssh == 'undefined'){
            console.log("Error establishing SSH Connection.");
          } else {
            ssh_conn = ssh;
            console.log("SSH Connection Stable");
          }
        });
      };
  me.config = {};
  me.lint = function(){
    try {
      if(me.config.type === 'local'){
        atom.workspace.eachEditor(function (editor) {
          editor.buffer.on('saved', handle_local);
        });
      } else {
        init_remote();
        atom.workspace.eachEditor(function (editor) {
          editor.buffer.on('saved', handle_remote);
        });
      }
    } catch(err){
      console.log("Lint Error");
      console.log(err)
    }
  };
};
