# Spec for testing the SecureRandom module

vows    = require 'vows'
should  = require 'should'

# The module to test. 
SecureRandom  = require("#{process.cwd()}/lib/util/secure_random").SecureRandom

exports.suite = vows.describe("Given the SecureRandom module").addBatch(
  'when generating a openssl secure hash':
    topic:()->
        hash1 = SecureRandom.secureToken("word")
        hash2 = SecureRandom.secureToken("tztw")
        return [hash1,hash2]
    'it should not be empty':(hashes)->
      [hash1,hash2] = hashes[0..-1]
      hash1.should.not.be.empty
      hash2.should.not.be.empty
    'it should be unique':(hashes)->
      [hash1,hash2] = hashes[0..-1]
      hash1.should.not.equal hash2

)