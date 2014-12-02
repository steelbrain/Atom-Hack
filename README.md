# Atom-Hack

> [Hack](https://github.com/facebook/hhvm) error reports for your [Atom](http://atom.io) editor.

Preview? Check out [CSSLint](https://github.com/tcarlsen/atom-csslint)

## Installation

Goto your .atom/packages directory and clone this repo there

```bash
cd ~/.atom/packages
git clone https://github.com/steelbrain/atom-hack --depth=1
cd atom-hack && npm install
```

## Usage

By default this plugin will assume that HHVM has been installed on the local machine, but if you're running HHVM in a VirtualMachine with shared folders, You can use that VirtualMachine to validate your Hack Code. To use this feature, You have to place something like this in your `Project Root/.atom-hack`
```
{
  "type":"remote",
  "host":"Remote Host's Domain or IP",
  "username":"Your Username",
  "port":22,
  "privateKey":"Full Path to Private Key",
  "remoteDir":"Directory on the remote server without the last slash"
}
```
This plugin will validate all files with C++ Grammar (.hh files have it), but you can change this behavior by setting `grammar` to a value in your .atom-hack file.
Note: Make sure to restart your Atom Editor after changing your configuration file.

## Features

 * Validation
 * Remote SSH Servers

## TODO

 * Remote SFTP Deployment (Being worked on, will land shortly)
 * Jump to Declaration
 * Auto-complete

## Current Limitations
* User must install open-last-project Atom package for Atom-Hack to work
* Errors are shown in a box at the bottom, however it could be turned into something fancy like [Atom-Lint](https://atom.io/packages/atom-lint)
* If the user is not using shared folders, the user has to use a separate sync software like WinSCP, it should be built-in into Atom-Hack.

## License

[MIT](http://opensource.org/licenses/MIT) © steelbrain
