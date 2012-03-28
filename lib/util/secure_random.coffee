crypto  = require 'crypto'
_       = require('./underscore_extension')._
Extensions.SecureRandom =
  secureToken:->
    sha       = crypto.createHash('sha512')
    key       = sha.update('key').digest('hex')
    cipher    = crypto.createCipher('aes-256-ecb', key)
    encrypted  = ""
    encrypted += cipher.update(_.randomString())
    encrypted += cipher.final('hex')
    return encrypted