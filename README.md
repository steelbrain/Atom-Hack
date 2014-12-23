# Atom-Hack

[HackLang](https://github.com/facebook/hhvm) support for [Atom editor](http://atom.io).

## Preview
![Preview](https://cloud.githubusercontent.com/assets/4278113/5449170/4b1597b2-8512-11e4-86f0-2ac210f68263.png)

## Installation

```bash
apm install atom-hack
```

## Usage

By default Atom-Hack assumes that HHVM is installed locally and needs zero-configuration if that's the case. But in case the server is remote, Please add this configuration to your `Project Root/.atom-hack`
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
 * Auto-Complete
 * Fancy Error Reporting

## TODO

 * Remote SFTP Deployment
 * Jump to Declaration

## Current Limitations
* If the user is using remote server and not sharing folders, the user has to use a separate sync software like WinSCP, it should be built-in into Atom-Hack.

## License

[QuickPress License](https://raw.githubusercontent.com/raeesiqbal/QuickPress/master/license.txt) © steelbrain
