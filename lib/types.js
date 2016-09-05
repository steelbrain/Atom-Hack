/* @flow */

export type Config = {
  type: 'local' | 'remote',
  host?: string,
  username?: string,
  uploadFiles?: boolean,
  privateKey?: string,
  remoteDirectory?: string
}
