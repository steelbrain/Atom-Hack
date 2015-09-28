'use babel'

const FS = require('fs')
const Path = require('path')
const SSH = require('node-ssh')
const Helpers = require('atom-linter')
import {promisify} from 'js-toolkit'
import {CompositeDisposable} from 'atom'

const readFile = promisify(FS.readFile)
const access = promisify(FS.access)

export default new class Hack {
  constructor() {
    this.subscriptions = new CompositeDisposable
    this.config = {
      type: 'local'
    }
    this.connected = true
    this.connection = null
    this.projectPath = null

    this.subscriptions.add(atom.project.onDidChangePaths(() => this.readConfig()))
    this.readConfig()
  }
  readConfig() {
    if (this.connection !== null) {
      this.connection.end()
      this.connection = null
    }
    const projects = atom.project.getPaths()
    if (!projects[0].length) {
      atom.notifications.addError('[Hack] No configuration file (.atom-hack) found in project root', {dismissible: true})
    } else {
      this.projectPath = projects[0]
      const configPath = Path.join(this.projectPath, '.atom-hack')
      access(configPath, FS.R_OK).catch(() => {
        if (process.platform === 'win32') {
          throw new Error('No configuration file (.atom-hack) found in project root')
        } else throw null
      }).then(() => {
        this.connected = false
        return readFile(configPath)
      }).then(contents => {
        try {
          contents = JSON.parse(contents.toString('utf8'))
        } catch (error) {
          throw new Error('Configuration file is not valid JSON')
        }
        contents.type = contents.type || 'remote'
        contents.port = contents.port || 22
        if (!contents.privateKey) {
          throw new Error('No privateKey specified in configuration')
        }
        if (!contents.remoteDir) {
          throw new Error('No remoteDir specified in configuration')
        }
        this.config = contents
        this.connection = new SSH()
        return this.connection.connect(this.config).then(() => {
          return this.connection.requestSFTP().then(sftp => {
            atom.notifications.addSuccess('[Hack] Successfully connected to server')
            this.connected = true
            this.connection.sftp = sftp
          }, err => {
            throw new Error('Error requesting SFTP from server: ' + err)
          })
        }, err => {
          throw new Error('Error Connecting to server: ' + err)
        })
      }).catch(err => {
        if (err)
          atom.notifications.addError('[Hack] ' + err.message)
      })
    }
  }
  update(localFile) {
    if (!this.connected || this.config.type !== 'remote' || !atom.config.get('linter.pushFilesToServer')) {
      return Promise.resolve()
    }
    return this.connection.put(localFile, this.convertPath(localFile), this.connection.sftp)
  }
  convertPath(localPath) {
    if (this.config.type === 'local') {
      return localPath
    } else {
      return Path.join(this.config.remoteDir, Path.relative(this.projectPath, localPath)).replace(Path.sep, '/')
    }
  }
  exec(command, args, options) {
    if (this.config.type === 'local') {
      return Helpers.exec(command, args, options)
    } else {
      return this.connection.exec(command, args, options)
    }
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
