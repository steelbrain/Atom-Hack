"use strict";
var path = require('path'),
    msgPanel = require('atom-message-panel'),
    exec = require('child_process').exec,
    ssh_connect = require('ssh2-connect'),
    ssh_exec = require('ssh2-exec'),
    init_status = 0,
    Promise = require('bluebird'),
    fs = require('fs'),
    config = {},
    ssh_conn, editor;
module.exports = new function () {
    var me = this,
        handle_local = function () {
            if (!validate())
                return;
            var dir = my_dir();
            exec('hh_client --json --from atom "' + dir + '"', function (_, __, response) {
                error_handle(response);
            });
        },
        handle_remote = function () {
            if (!validate())
                return;
            var dir = my_dir().replace(atom.project.path, config.remoteDir).split(path.sep).join('/');
            ssh_exec({
                cmd: 'hh_server --json --check "' + dir + '"',
                ssh: ssh_conn
            }, function (error, stdout, stderr) {
                error_handle(stderr);
            });
        },
        error_handle = function (stderr) {
            try {
                var output = JSON.parse(stderr);
                if (output.passed) {
                    msgPanel.destroy();
                } else {
                    var errors = [];
                    for (var i in output.errors) {
                        if (output.errors.hasOwnProperty(i)) {
                            var error = {
                                'code': output.errors[i]['message'][0]['code'],
                                'message': output.errors[i]['message'][0]['descr'],
                                'char_start': output.errors[i]['message'][0]['start'],
                                'char_end': output.errors[i]['message'][0]['end'],
                                'line': output.errors[i]['message'][0]['line'],
                                'file': output.errors[i]['message'][0]['path'].replace(config.remoteDir, atom.project.path).split('/').join(path.sep),
                                'trace': []
                            };
                            delete output.errors[i]['message'][0];
                            for (var ii in output.errors[i]['message']) {
                                if (output.errors[i]['message'].hasOwnProperty(ii)) {
                                    error.trace.push({
                                        'code': output.errors[i]['message'][ii]['code'],
                                        'message': output.errors[i]['message'][ii]['descr'],
                                        'char_start': output.errors[i]['message'][ii]['start'],
                                        'char_end': output.errors[i]['message'][ii]['end'],
                                        'line': output.errors[i]['message'][ii]['line'],
                                        'file': output.errors[i]['message'][ii]['path'].replace(config.remoteDir, atom.project.path).split('/').join(path.sep)
                                    });
                                }
                            }
                            errors.push(error);
                        }
                    }
                    error_multiple(errors);
                }
            } catch (err) {
                error_single(stderr);
            }
        },
        error_pre = function () {
            if (atom.workspaceView.find('.am-panel').length !== 1) {
                msgPanel.init('<span class="icon-bug"></span> Hack report');
            } else {
                msgPanel.clear();
            }
        },
        error_post = function () {
            atom.workspaceView.on('pane-container:active-pane-item-changed destroyed', function () {
                msgPanel.destroy();
            });
        },
        error_single = function (message) {
            error_pre();
            msgPanel.append.message(message, 'text-warning');
            error_post();
        },
        error_multiple = function (errors) {
            error_pre();
            var current_file = editor.getPath(), lines = [];
            for (var i in errors) {
                if (errors.hasOwnProperty(i)) {
                    if (errors[i].file === current_file) {
                        if(errors[i]['trace'].length === 0){
                            msgPanel.append.lineMessage(errors[i].line, errors[i].char_start, errors[i].message, errors[i]['trace'].join("\n"), 'text-warning');
                        } else {
                            var trace = [];
                            for(var ii in errors[i]['trace']){
                                if(errors[i]['trace'].hasOwnProperty(ii)){
                                    trace.push(errors[i]['trace'][ii].message + ' @Line# ' + errors[i]['trace'][ii].line + ' Col ' + errors[i]['trace'][ii].char_start + ' in file ' + errors[i]['trace'][ii].file);
                                }
                            }
                            msgPanel.append.lineMessage(errors[i].line, errors[i].char_start, errors[i].message, trace.join("\n"), 'text-warning');
                        }
                    } else {
                        msgPanel.append.message(errors[i].message + ' @Line# ' + errors[i].line + ' Col ' + errors[i].char_start + ' in file ' + errors[i].file, 'text-warning');
                    }
                }
            }
            error_post();
        },
        validate = function () {
            editor = atom.workspace.getActiveEditor();
            return !!editor && editor.getGrammar().name === config.grammar;
        },
        my_dir = function () {
            return path.dirname(editor.getPath()).replace('"', '\"');
        },
        init_remote = function () {
            return new Promise(function (callback) {
                ssh_connect({
                    host: config.host,
                    port: config.port,
                    username: config.username,
                    privateKeyPath: config.privateKey
                }, function (err, ssh) {
                    if (typeof ssh == 'undefined') {
                        console.log("Error establishing SSH Connection.");
                    } else {
                        callback();
                        ssh_conn = ssh;
                        console.log("SSH Connection Stable");
                    }
                });
            });
        },
        init_config = function () {
            return new Promise(function (callback) {
                if (fs.existsSync(atom.project.path + '/.atom-hack')) {
                    fs.readFile(atom.project.path + '/.atom-hack', 'utf-8', function (_, result) {
                        config = JSON.parse(result);
                        config.grammar = config.grammar || 'C++';
                        config.port = config.port || 22;
                        config.type = config.type || 'local';
                        callback();
                    });
                } else {
                    config = {
                        type: "local",
                        grammar: "C++"
                    };
                    callback();
                }
            });
        };
    me.init = function () {
        try {
            atom.workspace.eachEditor(function (editor) {
                editor.buffer.on('saved', function () {
                    if (init_status === 0) {
                        init_status = 2;
                        init_config().then(function () {
                            init_status = 1;
                            if (config.type === 'local') {
                                handle_local();
                            } else {
                                init_remote().then(handle_remote);
                            }
                        });
                    } else if (init_status === 1) {
                        if (config.type === 'local') {
                            handle_local();
                        } else {
                            handle_remote();
                        }
                    }
                });
            });
        } catch (err) {
            console.log("Lint Error");
            console.log(err)
        }
    };
};
