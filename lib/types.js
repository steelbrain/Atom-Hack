/* @flow */

export type Config = {
  type: 'local' | 'remote',
  host?: string,
  username?: string,
  privateKey?: string,
}
