# Atom-Hack [![Build Status](https://travis-ci.org/steelbrain/Atom-Hack.svg)](https://travis-ci.org/steelbrain/Atom-Hack) [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/steelbrain/atom-hack)


[HackLang](https://github.com/facebook/hhvm) support for [Atom editor](http://atom.io).
AutoComplete has split into a separate Package [Hack-AutoComplete][HA].

## Preview
![Preview](https://cloud.githubusercontent.com/assets/4278113/5449170/4b1597b2-8512-11e4-86f0-2ac210f68263.png)

## Installation

```bash
apm install atom-hack
```

## Usage

By default Atom-Hack assumes that HHVM is installed locally and needs zero-configuration if that's the case. But in case the server is remote, Please add this configuration to your `Project Root/.atom-hack` (autoPush means auto-upload file to remote server onSave)
```js
{
  "type":"remote",
  "host":"Remote Host's Domain or IP",
  "username":"Your Username",
  "passphrase":"Your passphrase (Or exclude this line if you do not have one)",
  "port":22,
  "privateKey":"Full Path to Private Key",
  "remoteDir":"Directory on the remote server without the last slash",
  "autoPush":false
}
```
This plugin will validate all .hh, .php files and the files starting with <?hh or <?php

__Note__: Make sure to restart your Atom Editor after changing your configuration file.

## Features

 * Validation
 * Remote SSH Servers
 * Remote SFTP Deployment

## License

MIT License © steelbrain

[HA]:https://github.com/steelbrain/AutoComplete-Hack