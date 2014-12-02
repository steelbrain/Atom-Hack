var linter = require('./linter'),
    fs = require('fs'),
    init = function(){
      if(fs.existsSync(atom.project.path+'/.atom-hack')){
        fs.readFile(atom.project.path+'/.atom-hack','utf-8',function(_,result){
          linter.config = JSON.parse(result);
          linter.config.grammar = linter.config.grammar || 'C++';
          linter.config.port = linter.config.port || 22;
          linter.config.type = linter.config.type || 'local';
          linter.lint();
        });
      } else {
        linter.config = {
          type:"local",
          grammar:"C++"
        };
        linter.lint();
      }
    };
module.exports = {
  atomHackView: null,
  activate: function(){
    setTimeout(init,5000);
    console.log("Activated")
  },
  deactivate: function() {
    console.log("Deactivating")
  }
};
