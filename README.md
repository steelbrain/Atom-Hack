# Atom-Hack

[Hack](https://github.com/facebook/hhvm) type checking and auto-completion for [Atom editor](http://atom.io).

## Preview
![Preview](https://cloud.githubusercontent.com/assets/4278113/5449170/4b1597b2-8512-11e4-86f0-2ac210f68263.png)

## Installation

```bash
apm install atom-hack
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
This plugin will validate all .hh, .php files and the files starting with <?hh or <?php
Note: Make sure to restart your Atom Editor after changing your configuration file.

## Features

 * Validation
 * Remote SSH Servers

## TODO

 * Remote SFTP Deployment (Being worked on, will land shortly)
 * Jump to Declaration
 * ~~Auto-complete~~

## Current Limitations
* ~~Errors are shown in a box at the bottom, however it could be turned into something fancy like [Atom-Lint](https://atom.io/packages/atom-lint)~~
* If the user is using remote server and not sharing folders, the user has to use a separate sync software like WinSCP, it should be built-in into Atom-Hack.

## License

[MIT](http://opensource.org/licenses/MIT) © steelbrain
