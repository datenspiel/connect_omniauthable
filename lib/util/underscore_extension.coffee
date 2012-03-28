_ = require "underscore"

###
  A collection of useful methods which are not included in
  underscore.js by default.

  @author Daniel Schmidt, Datenspiel GmbH 2012
###

urlMatcher =
  # Test a string if it is a valid url (only http/https)
  # 
  # Matches: 
  #    http://www.blah.com/~joe | https://blah.gov/blah-blah.as
  # Non-Matches:
  #    ftp://ftp.blah.co.uk:2828/blah%20blah.gif | www.blah.com 
  #    http://www.blah&quot;blah.com/I have spaces! 
  # 
  # url - The string which should be tested.
  #
  # Returns true if url is valid otherwise false. 
  isValidUrl : (url)->
    matchExpression = new RegExp("^(http|https)\://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(:[a-zA-Z0-9]*)?/?([a-zA-Z0-9\-\._\?\,\'/\\\+&amp;%\$#\=~])*[^\.\,\)\(\s]$")
    match = url.match(matchExpression)
    return match?

  # Generates a random String and returns it.
  randomString:->
    Math.random().toString(36).substring(7)

# Extend underscore.js with own modules
_.mixin(urlMatcher)


exports._ = _