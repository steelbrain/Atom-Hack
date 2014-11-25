/*global atom, require, module*/

var linter = require('./linter');

module.exports = {
    configDefaults: {
        validateOnSave: true,
        hideOnNoErrors: false,
        useFoldModeAsDefault: false
    },
    activate: function () {
        'use strict';

        atom.config.observe('hack.validateOnSave', {callNow: true}, function (value) {
            if (value === true) {
                atom.workspace.eachEditor(function (editor) {
                    editor.buffer.on('saved', linter);
                });
            } else {
                atom.workspace.eachEditor(function (editor) {
                    editor.buffer.off('saved', linter);
                });
            }
        });
    }
};
