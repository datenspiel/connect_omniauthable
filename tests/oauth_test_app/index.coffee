# This is a test web application to test OAuth workflows.
# 
# Will be used with cucumber.js
#
# Start the OAuth Server on port 3001
# 
# @author Daniel Schmidt
require "common_dwarf_mongoose"
http            = require "http"
mongo           = require "mongoose"
connect         = require "connect"
ResponseHeader  = require("#{process.cwd()}/lib/util/response")
Templater       = require("#{process.cwd()}/lib/util/templater")
Client          = require("#{process.cwd()}/lib/models/client")
_               = require("#{process.cwd()}/lib/util/underscore_extension")._
qs              = require 'querystring'
routeMatcher    = require('routematcher').routeMatcher

# Connect to database.
mongo.connect('mongodb://localhost/ovu_oauth_server')

# Create a new Client
client = new Client()
client.set('client_id': _.randomString())
client.set('secret':_.randomString())
client.set('application_name':'OAuth Test client')
client.set('redirect_uri':'http://localhost:3000/oauth/cb')

templater = new Templater()
templater.setTemplateRoot("#{process.cwd()}/tests/oauth_test_app/views/")

state = _.randomString()

### helpers ####
writeResponse = (res,data)->
  res.write(data)
  res.end()


saveCallback = (err,client)->
  throw err if err
  console.log client
  app = do connect

  oauthTest = ()->
    return (req,res,next)->
      #console.log res
      rh = new ResponseHeader(res)
      [url,paramsFromUrl] = req.url.split('?')
      indexMatcher = routeMatcher("/")
      callbackMatcher = routeMatcher("/oauth/cb")
      postFakerMatcher = routeMatcher("/fake/access_token")
      index(req,res,client,rh) if indexMatcher.parse(url)?
      cb(req,res,client,rh) if callbackMatcher.parse(url)?
      accessTokenRequest(req,res,client,rh) if postFakerMatcher.parse(url)?

  app.use connect.bodyParser()
  app.use oauthTest()

  app.listen 3000

# save client
client.save(saveCallback)

# index route
index = (req,res,client,rh)->
  rh.setHtml()
  client = Client.becomesFrom(client)
  
  templateOptions =
    template: "index"
    locals: 
      client: client.getApplicationName()
      client_id: client.getClientId()
      redirect_uri: client.getRedirectUri()
      state: state
  template = templater.compile(templateOptions)
  writeResponse(res,template)

# callback route
cb = (req,res,client,rh)->
  client = Client.becomesFrom(client)
  [url,paramsFromUrl] = req.url.split('?')
  params = qs.parse(paramsFromUrl)
  if req.method is 'GET'
    oauthCallbackGET(req,res,client,rh,params) unless params.hasOwnProperty("error")
  oauthCallbackPOST(req,res,client,rh) if req.method is 'POST'

oauthCallbackGET = (req,res,client,rh,params)->
  rh.setHtml()
  #console.log req.url
  additionalParams =
    state_from_server:state
    client_id : client.getClientId()
    client_secret : client.getSecret()
    redirect_uri: client.getRedirectUri()
  _.extend(params,additionalParams)
  templateOptions =
    template: "cb"
    locals: params
  template = templater.compile(templateOptions)
  writeResponse(res,template)

accessTokenRequest = (req,res,client,rh,params)->
  post_data = qs.stringify(req.body)
  post_options = 
    host: 'localhost'
    port: '3001'
    path: '/o/oauth2/access_token'
    method: 'POST'
    headers:
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': post_data.length
    
  post_request = http.request(post_options,(response)->
    response.setEncoding('utf8')
    response.on('data',(chunk)->
      writeResponse(res,templater.compile({template:'token',locals:JSON.parse(chunk)}))
    )
  )

  post_request.write(post_data)
  post_request.end()
  
