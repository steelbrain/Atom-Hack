'use babel'

const FS = require('fs')
const Path = require('path')
const SSH = require('node-ssh')
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
      Hack.notificationNoConfig()
    } else {
      const configPath = Path.join(projects[0], '.atom-hack')
      access(configPath, FS.R_OK).catch(() => {
        throw new Error('No configuration file (.atom-hack) found in project root')
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
        this.connection = new SSH(this.config)
        return this.connection.connect().then(() => {
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
        atom.notifications.addError('[Hack] ' + err.message)
      })
    }
  }
  dispose() {
    this.subscriptions.dispose()
  }

  static notificationNoConfig() {
    if (process.platform === 'win32') {
      atom.notifications.addWarning('[Hack] No configuration file (.atom-hack) found in project root', {dismissable: true})
    }
  }
}
