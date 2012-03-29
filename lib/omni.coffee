mongo   = require 'mongoose'
require "common_dwarf_mongoose"
config  = require "./oauth_config"
require "./server"
routeMatcher = require('routematcher').routeMatcher

# The main middleware method. 
# It initializes the OAuthServer and delegates the requests 
# to the responsible method.
#
# options       - The options map to configure the oauth server 
#     database  - The database name as string
#
class oauth
  constructor: (options)-> 
    database = if options.hasOwnProperty("database") then options.database else "oauth_server"

    mongo.connect("mongodb://localhost/#{database}")
    return (req,res,next)->
      server = new OAuthServer(req,res,next) 
      # authenticate a client
      url = server.url
      authenticateClientMatcher = routeMatcher(config.oauth_config.authorizationUrlBase)
      denyClientAccessMatcher   = routeMatcher(config.oauth_config.denyClientAccessURL)
      grantClientAccessMatcher  = routeMatcher(config.oauth_config.grantClientAccessURL)
      accessTokenRequestMatcher = routeMatcher(config.oauth_config.accessTokenRequestEndpointURL)

      if authenticateClientMatcher.parse(url)?
        server.authenticateClient() 
      else if grantClientAccessMatcher.parse(url)?
        server.grantClientAccess()
      else if accessTokenRequestMatcher.parse(url)?
        server.requestAccessToken()
      else if denyClientAccessMatcher.parse(url)?
        denyAccessParams = denyClientAccessMatcher.parse(url)
        server.denyClientAccess(denyAccessParams['id'],denyAccessParams['state'])
      else
        # pass through authenticate if nothing other matches
        server.authenticateWithAccessToken()
         
module.exports = oauth