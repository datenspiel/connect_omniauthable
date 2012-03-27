crypto = require 'crypto'

SecureRandom =
  secureToken:(id)->
    sha       = crypto.createHash('sha512')
    key       = sha.update('key').digest('hex')
    cipher    = crypto.createCipher('aes-256-ecb', key)
    encrypted  = ""
    encrypted += cipher.update(id)
    encrypted += cipher.final('hex')
    return encrypted

exports.SecureRandom = SecureRandom