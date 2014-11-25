var msgPanel = require('atom-message-panel'),
    exec = require('child_process').exec,
    className = 'text-warning';

module.exports = function () {
    'use strict';

    var editor = atom.workspace.getActiveEditor(),
        path,
        result,
        error,
        lines = [],
        i;

    if (!editor) {
        return;
    }

    if(editor.getGrammar().name === 'C++') {
        var file = editor.getPath();
        if (file.indexOf("/") == -1) { // windows
            path = file.substring(0, file.lastIndexOf('\\'));
        }
        else { // unix
            path = file.substring(0, file.lastIndexOf('/'));
        }
        exec('hh_client "'+(path.replace('"','\"'))+'"', function (errors, response) {
            response = response.split("\n");
            if (atom.workspaceView.find('.am-panel').length !== 1) {
                msgPanel.init('<span class="icon-bug"></span> Hack report');
            } else {
                msgPanel.clear();
            }
            var error_encountered = false;
            for (i = 0; i < response.length; i += 1) {
                if(response.hasOwnProperty(i)){
                    error = (response[i]).trim();
                    error = error.split(':');
                    var error_file = error[0],
                        error_line = error[1],
                        error_chars = error[2],
                        error_message = error[3];
                    if(error.length < 1 || typeof error_chars == 'undefined')continue;
                    error_encountered = true;
                    if(file == error_file) {
                        lines.push(error_line);

                        msgPanel.append.lineMessage(error_line, (error_chars.split(','))[0], error_message, "", className);
                    } else {
                        msgPanel.append.message(error.join(':'), className);
                    }
                }
            }
            if(!error_encountered){
                msgPanel.destroy();
            }

            msgPanel.append.lineIndicators(lines, 'text-error');

            atom.workspaceView.on('pane-container:active-pane-item-changed destroyed', function () {
                msgPanel.destroy();
                atom.workspaceView.find('.line-number').removeClass('text-error');
            });
        });
    }
};
