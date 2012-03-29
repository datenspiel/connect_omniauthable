mongo   = require 'mongoose'
require "common_dwarf_mongoose"
config  = require "./oauth_config"
require "./server"
routeMatcher = require('routematcher').routeMatcher

mongo.connect('mongodb://localhost/ovu_oauth_server')

# The main middleware method. 
# It initializes the OAuthServer and delegates the requests 
# to the responsible method. 
class oauth
  constructor: (codestring)-> 
    options = codestring.toUpperCase() if codestring?
    return (req,res,next)->
      server = new OAuthServer(req,res,next) 
      # authenticate a client
      url = server.url
      authenticateClientMatcher = routeMatcher(config.oauth_config.authorizationUrlBase)
      denyClientAccessMatcher   = routeMatcher(config.oauth_config.denyClientAccessURL)
      grantClientAccessMatcher  = routeMatcher(config.oauth_config.grantClientAccessURL)
      accessTokenRequestMatcher = routeMatcher(config.oauth_config.accessTokenRequestEndpointURL)
      server.authenticateClient() if authenticateClientMatcher.parse(url)?
      server.grantClientAccess()  if grantClientAccessMatcher.parse(url)?
      server.requestAccessToken() if accessTokenRequestMatcher.parse(url)?
      denyAccessParams = denyClientAccessMatcher.parse(url)
      if denyAccessParams?
        server.denyClientAccess(denyAccessParams['id'],denyAccessParams['state'])
        

      #server.authenticateClient(req,res,next) if server.url is config.oauth_config.authorizationUrlBase
      #server.other(options) if server.url is '/persons'
      
      # Pass through to the next layer if nothing matches...
      next() if url is "/"

module.exports.omni_auth = oauth