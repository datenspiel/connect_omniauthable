mongo   = require 'mongoose'
require "common_dwarf_mongoose"
config  = require "./oauth_config"
routeMatcher  = require('routematcher').routeMatcher
_             = require("./util/underscore_extension")._

# The main middleware method. 
# It initializes the OAuthServer and delegates the requests 
# to the responsible method.
# 
# options       - The options map to configure the oauth server 
#     database  - The database name as string
#     host      - The database host
class oauth
  constructor: (options)-> 
    unless _.isEmpty(options)
      database    = if options.hasOwnProperty("database") then options.database else "oauth_server"
      host        = if options.hasOwnProperty("database_host") then options.database_host else "localhost" 
      
      global.oauth_connection = mongo.createConnection("mongodb://#{host}/#{database}")
      require "./server"

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