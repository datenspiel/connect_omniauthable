# Spec for testing the url_matcher method which is
# mixed in underscore.js in /lib/util/underscore_extension

vows    = require "vows"
should  = require "should"

# The module to test.
_       = require("#{process.cwd()}/lib/util/underscore_extension")._


exports.suite = vows.describe('Testing an url with regular expression').addBatch(
  'when having an http url':
    topic:()->
      return "http://regexplib.com/REDetails.aspx?regexp_id=153"
    'it matches and the url is fine':(url)->
      _(url).isValidUrl().should.be.true
  'when having an https url':
    topic:()->
      return "https://regexplib.com/REDetails.aspx?regexp_id=153"
    'it matches and the url is fine':(url)->
      _(url).isValidUrl().should.be.true
  'when having an ftp url':
    topic:()->
      return "ftp://ftp.blah.co.uk:2828/blah%20blah.gif "
    'it did not matches and url is not fine':(url)->
      _(url).isValidUrl().should.be.false
) 