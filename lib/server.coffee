config  = require "./oauth_config"
qs      = require 'querystring'
path    = require 'path'
jade    = require 'jade'
fs      = require 'fs'
_       = require('./util/underscore_extension')._


Client      = require("./models/client").Client
AccessGrant = require("./models/grant_access").AccessGrant
AccessToken = require("./models/access_token").AccessToken

# Error response types as described in draft-ietf-oauth-v2-23
# section 4.1.2.1
responseError = 
  access            : "access_denied"
  unauthorized      : "unauthorized_client"
  request           : "invalid_request"
  unsupported_type  : "unsupported_response_type"
  scope             : "invalid_scope"
  server            : "server_error"
  unavailable       : "temporarily_unavailable"

class parseBody
  constructor: (req,res)->
    body = ''
    req.on('data', (data)->
      body += data
    )
    return req.on('end', ()->
      POST = qs.parse(body)
      return POST
    )

# A wrapper around the node/connect response object with 
# some useful methods.
class ResponseHeader
  constructor:(@response)->

  # Sets the response header to text/html.
  setHtml:->
    @response.setHeader("Content-Type", "text/html")

  # Sets the response header to a given location and 
  # the status code to 302 (FOUND)
  #
  # url - An url to which the browser should be redirected.
  setLocation:(url)->
    @response.statusCode = 302
    @response.setHeader("Location", url)

  # Redirects the browser to the given URL.
  #
  # url - An url to which the browser should be redirected.
  redirectTo:(url)->
    @setLocation(url)
    @response.end()

# A template class which compiles Jade templates with its locales 
# into valid html.
class Templater
  # The template root absolute to the dir of this file. 
  @templatesRoot: path.join(__dirname, 'views')

  # Compiles a template and pass it to a callback.
  #
  # options - The argument options to compile the template.
  #     :template - name of the template (without *.jade extension)
  #     :locals   - contains the key/values for the variables in the template
  #     :cb       - a callback function which expects the compiled template
  #                 and a response object
  #     :res      - the response object
  @compile:(options)->
    callback = options.cb
    response = options.res
    compiledTemplate = jade.compile(@readTemplate(options.template))(options.locals)
    callback(compiledTemplate,response)

  # Reads a template from templates root
  # 
  # name - name of the template without file extension
  #
  # Returns the content of the template.
  @readTemplate:(name)->
    return fs.readFileSync(path.join(@templatesRoot,"#{name}.jade"))

# The main class which acts as OAuth authentication server.
#
class OAuthServer

  # Initializes the OAuthServer class.
  # 
  # req   - A request object instance.
  # res   - A node/connect response object instance.
  # next  - A connect middleware delegator which could delegate
  #         requests to the next layer.
  #
  # Returns a new OAuthServer instance. 
  constructor: (@req,@res,@next)->
    # split url into suffix and possible params
    [@url,@paramsFromUrl] = @req.url.split('?')
    @responseHeader = new ResponseHeader(@res)
  
  ###
  Used if the url matches oauth_config.authorizationUrlBase. 
  (See lib/oauth_config.coffee).
  
  Method: GET 

  The following query parameters are required:
    
    * response_type (which is typical set to 'code')
    * client_id 
    * redirect_uri

  Recommend and required with this implementation:

    * state - used for preventing CSRF 

  Optional parameters are

    * scope

  ###
  authenticateClient: ->
    params = qs.parse(@paramsFromUrl)
    unless Mongoose.Base.isEmpty(params)
      # Params are not empty, so some are send. 
      # Check if params are included.
      @validateAuthorizationParams(params)
  
      # Is client present?
      Client.find({'client_id':params['client_id']},(err,records)=>
        console.log "records are #{records.length}"
        if records.length is 0
        #  # no client registered => error
          @unauthorizedRequest(params, responseError.unauthorized)
        else
          client = Client.becomesFrom(records[0])
          # Check if the persisted redirect_uri matches the 
          # redirect_uri from params
          if client.getRedirectUri() isnt params['redirect_uri']
            # redirect back to redirect_uri from params with error parameter
            @unauthorizedRequest(params, responseError.access)
          else
            localVars = 
              client: client.getApplicationName()
              client_id: client.getClientId()
              state: params['state']
          
            @responseHeader.setHtml()
            compileOptions =
              template: "auth_endpoint"
              locals: localVars
              cb: @writeResponse
              res: @res
            Templater.compile(compileOptions)
          
      )

    else
      # Error handling for missing parameters.
      @handleError({msg: "Missing parameters!"})

  # Used if the url matches oauth_config.denyClientAccessURL. 
  # (See lib/oauth_config.coffee).
  #
  # Redirects the browser back to 'redirect_uri' with an access_denied
  # error code.
  #
  # Method: GET
  #
  # client_id - The client id with which the client is registered at OAuth Server
  # state     - The value of the state parameter passed in the initial request
  #             (see #authenticateClient)
  #
  denyClientAccess:(client_id,state)->
    Client.find({'client_id':client_id},(err,records)=>
      console.log(err) if err
      if records.length is 0
      else
        client = Client.becomesFrom(records[0])
        params = 
          redirect_uri  : client.getRedirectUri()
          state         : state
        @unauthorizedRequest(params, responseError.access)

    )

  # Used if the url matches oauth_config.grantClientAccessURL. 
  # (See lib/oauth_config.coffee)
  #
  # Method: POST
  # 
  # Adds a new AccessGrant for the client which was granted access.
  # Redirects the browser back to redirect_uri with the authorization code.
  grantClientAccess:->
    clientId = @req.body.client_id
    state    = @req.body.state
    # What happens if GrantAccess for given client exists? Since the authorization 
    # code is unique I would say that this is ignorable. 

    # new grant access
    accessGrant = new AccessGrant()
    accessGrant.set('client_id':clientId)
    accessGrant.save()
    AccessGrant.find({'client_id':clientId,'revoked':false,'created_at':accessGrant.getCreatedAt()},(err,docs)=>
      # We assume there is only one.
      grant = AccessGrant.becomesFrom(docs[0])
      Client.find({'client_id':clientId}, (err,clients)=>
        client = Client.becomesFrom(clients[0])
        redirectUri = client.getRedirectUri()
        @responseHeader.redirectTo("#{redirectUri}?code=#{grant.getAuthorizationCode()}&state=#{state}")
      )
    )

  # Used if the url matches oauth_config.accessTokenRequestEndpointURL.
  # (See lib/oauth_config.coffee)
  #
  # Method: POST
  #
  # The following parameters are required:
  #
  #   * code          - The authorization code which was send by #grantClientAccess
  #   * redirect_uri  - The location registered and used in the initial request (#authenticateClient)
  #   * grant_type    - The value 'authorization_code'
  #   * client_id     - The client id with which the client is registered.
  #   * client_secret - The client secret with which the client is registered
  #
  # It authorizes the client and if this is done and all above listed parameters
  # are valid it sends an Access Token Response as json.
  requestAccessToken:->
    params = 
      code          : @req.body.code
      redirect_uri  : @req.body.redirect_uri
      grant_type    : @req.body.grant_type
      client_id     : @req.body.client_id
      client_secret : @req.body.client_secret

    @validateAccessTokenParams(params)


  # Test method. 
  # Should be removed in later versions.
  other: (options)->
    console.log "config is"
    console.log config.oauth_config  
    console.log @req.body 
    console.log "url #{@url}"
    parseBody(@req,@res) if @req.method is 'POST'
    console.log "params :"
    console.log qs.parse(@paramsFromUrl)
    @res.statusCode = "201"
    console.log(options)
    @res.write(JSON.stringify({"name": options}))
    @res.end()

  # Handles any unathorized requests. 
  # See OAuth spec at IETF section 4.1.2.1
  #
  # params  - Parameters which are described in #authenticateClient
  # code    - An error code which could be:
  #             - access_denied
  #             - unauthorized_client
  #             - invalid_request
  unauthorizedRequest:(params,code)->
    @responseHeader.redirectTo("#{params["redirect_uri"]}?error=#{code}&state=#{params['state']}")

  # Handles any kind of occured errors.
  handleError:(options)->
    console.log options
    msg = if options.msg? then options.msg else "Something is missing"
    @responseHeader.setHtml()
    localVars = 
      errorMsg: msg
    compileOptions =
      template: "failure"
      locals: localVars
      cb: @writeResponse
      res: @res

    Templater.compile(compileOptions)

  # Validates the params as described in #authenticateClient
  # 
  # params - A parameter map which is described in #authenticateClient
  #
  # It calls #handleErrors if an error occured otherwise it returns nothing. 
  validateAuthorizationParams:(params)->
    required = ['client_id', 'response_type', 'redirect_uri','state']
    errors = []
    for parameter in required
      unless params.hasOwnProperty(parameter) or params[parameter] is ''
        errors.push({missing: parameter})

    unless _(params['redirect_uri']).isValidUrl()
      errors.push({errorMsg: 'invalid URL format for redirect_uri'})

    @handleError(errors) unless _.isEmpty(errors)

  # Validates the params which are required in #requestAccessToken.
  # 
  # params - A paramater map which contains
  #   code          - The authorization code which was send by #grantClientAccess
  #   redirect_uri  - The location registered and used in the initial request (#authenticateClient)
  #   grant_type    - The value 'authorization_code'
  #   client_id     - The client id with which the client is registered.
  #   client_secret - The client secret with which the client is registered
  #
  # If any error occurs #handleErrors is called (described in section 5.2)
  # otherwise it returns nothing
  validateAccessTokenParams:(params)->
    required = ['code', 'redirect_uri', 'grant_type','client_id', 'client_secret']
    errors = []
    for parameter in required
      if params[parameter] is ''
        errors.push({error: "#{parameter} is empty but required."})
    unless _(params['redirect_uri']).isValidUrl()
      errors.push({error: 'invalid URL format for redirect_uri.'})
    unless params['grant_type'] isnt 'authorization_code'
      errors.push({error: 'Invalid type for grant_type.'})

    @handleErrors(errors, {type: "json"}) unless _.isEmpty(errors)

  # Writes any given data to the response object and sends it.
  # 
  # data - Any data (could be compiled HTML or JSON)
  # res  - An http response object.
  writeResponse:(data,res)->
    res.write(data)
    res.end()

# Export OAuthServer class to the global Node system.
global.OAuthServer = OAuthServer