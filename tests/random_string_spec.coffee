# Sepc for testing the randomString method which is
# mixed in underscore.js in /lib/util/underscore_extension

vows    = require "vows"
should  = require "should"

# The module to test
_       = require("#{process.cwd()}/lib/util/underscore_extension")._

exports.suite = vows.describe("Generate a random string").addBatch(
  'when having two strings generated':
    topic:->
      s1 = _.randomString()
      s2 = _.randomString()
      return [s1,s2]
    'they are not equal':(strings)->
      [s1,s2] = strings
      s1.should.not.equal s2
) 