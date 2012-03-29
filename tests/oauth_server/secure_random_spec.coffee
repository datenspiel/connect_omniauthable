# Spec for testing the SecureRandom module
require 'common_dwarf_mongoose'

vows    = require 'vows'
should  = require 'should'

# The module to test. 
require("#{process.cwd()}/lib/util/secure_random")

exports.suite = vows.describe("Given the SecureRandom module").addBatch(
  'when generating a openssl secure hash':
    topic:()->
        hash1 = Extensions.SecureRandom.secureToken()
        hash2 = Extensions.SecureRandom.secureToken()
        return [hash1,hash2]
    'it should not be empty':(hashes)->
      [hash1,hash2] = hashes
      hash1.should.not.be.empty
      hash2.should.not.be.empty
    'it should be unique':(hashes)->
      [hash1,hash2] = hashes
      hash1.should.not.equal hash2

)