mongo   = require 'mongoose'
require "common_dwarf_mongoose"
config  = require "./oauth_config"
require "./server"
require "./models/access_token"
Client  = require("./models/client").Client
routeMatcher = require('routematcher').routeMatcher

mongo.connect('mongodb://localhost/ovu_oauth_server')

# The main middleware method. 
# It initializes the OAuthServer and delegates the requests 
# to the responsible method. 
class oauth
  constructor: (codestring)-> 
    
    options = codestring.toUpperCase()
    return (req,res,next)->
      server = new OAuthServer(req,res,next) 
      # authenticate a client
      url = server.url
      authenticateClientMatcher = routeMatcher(config.oauth_config.authorizationUrlBase)
      server.authenticateClient(req,res,next) if authenticateClientMatcher.parse(url)?
        

      #server.authenticateClient(req,res,next) if server.url is config.oauth_config.authorizationUrlBase
      #server.other(options) if server.url is '/persons'
      
      # Pass through to the next layer if nothing matches...
      #next()

module.exports.omni_auth = oauth