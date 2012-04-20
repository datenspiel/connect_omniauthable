config          = require "./oauth_config"
qs              = require 'querystring'
_               = require('./util/underscore_extension')._
Client          = require("./models/client")
AccessGrant     = require("./models/grant_access")
AccessToken     = require("./models/access_token")
Templater       = require("./util/templater")
ResponseHeader  = require("./util/response")

# Require mixin modules
require "./util/validations"
require "./util/secure_random"

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

class Server extends Mixin.Base



# The main class which acts as OAuth authentication server.
#
class OAuthServer extends Server
  @include Extensions.Validations
  @include Extensions.SecureRandom
  
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
    @templater = new Templater()
  
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
      paramsValidation = @validateAuthorizationParams(params)
    
      # if paramsValidation has any return type and this return type is true
      if paramsValidation? and paramsValidation

        # Is client present?
        Client.find({'client_id':params['client_id']},(err,records)=>
          
          #console.log "records are #{records.length}"
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
              @templater.compile(compileOptions)
          
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
    # code is unique I would say that this is ignorable and maybe there are more 
    # grants for a client (different user maybe).

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
  #
  # Note: There is no support for expired tokens by now.
  requestAccessToken:->
    params = 
      code          : @req.body.code
      redirect_uri  : @req.body.redirect_uri
      grant_type    : @req.body.grant_type
      client_id     : @req.body.client_id
      client_secret : @req.body.client_secret

    accessTokenParamsValid = @validateAccessTokenParams(params)
    if accessTokenParamsValid? and accessTokenParamsValid
      # Authenticate the client with client_id and client_secret
      Client.find({client_id: params.client_id, secret:params.client_secret}, (err,clients)=>
        if _.isEmpty(clients)
          @unauthorizedRequest({redirect_uri: params.redirect_uri},responseError.unauthorized) 
        else
          # There is a client registered.
          client = Client.becomesFrom(clients[0])
          # Check if an access grant is available for this client and make sure that the
          # access grant isn't expired.
          # Note that AccessGrant#_id is the authorization code.
          AccessGrant.find({"_id": "#{params.code}", client_id: client.getClientId()}, (err,grants)=>
            @unauthorizedRequest({redirect_uri: params.redirect_uri}, responseError.access) if _.isEmpty(grants)
            # There is grant for this client with this code. 
            grant = AccessGrant.becomesFrom(grants[0])
            # Check if the grant is expired.
            now = new Date()
            if now < grant.getGrantAccessExpireDate()
              # Check if grant was revoked before
              unless grant.isRevoked()
                # Grant is not expired, continue with generating an AccessToken
                # Generate an access token 
                accessToken = new AccessToken()
                accessToken.set('client_id': client.getClientId())
                accessToken.save((err,document)=>
                  throw err if err
                  if document?
                    # Updates the client grant token count and send the access token response if 
                    # updating succeeds.
                    Client.update({"_id": "#{client.getId()}"}, { $inc: { tokens_granted: 1} }, {}, (err,numEffected)=>    
                      if numEffected > 0
                        # Revoke the access grant to make sure it is used only once. 
                        AccessGrant.update({"_id": "#{grant.getId()}"},{revoked: true, granted_at: new Date()}, {},(err,grantsEffected)=>
                          token = AccessToken.becomesFrom(document)
                          # clients token_granted is incremented successfully
                          # Send a response as JSON
                          tokenResponse = 
                            access_token  : token.getAccessToken()
                            token_type    : "bearer"
                          @responseHeader.setJSON()                     
                          @writeResponse(JSON.stringify(tokenResponse),@res)
                        ) 
                    ) 
                )
              else
                # Grant was revoked before and is used more than once here.
                @unauthorizedRequest({redirect_uri: params.redirect_uri}, responseError.access)
            else
              # Access grant is expired.
              @unauthorizedRequest({redirect_uri: params.redirect_uri}, responseError.access)
          )
      )

  # Authenticates a request at the OAuth Server and passes it through
  # the next level if the request is authorized. If not it sends an 
  # JSON error response:
  #
  #   * error               - The error type (access_denied)
  #   * error_description   - The description why the error occured
  authenticateWithAccessToken:->
    params = qs.parse(@paramsFromUrl)
    unless params.hasOwnProperty("access_token")
      @unauthorizedRequestWithAccessToken(JSON.stringify({error: responseError.access}))
    else
      # find an access token with this one given in params
      AccessToken.find({access_token : params["access_token"]},(err,tokens)=>
        if _.isEmpty(tokens)
          @unauthorizedRequestWithAccessToken(JSON.stringify({error: responseError.access})) 
        else
          accessToken = AccessToken.becomesFrom(tokens[0])
          if accessToken.isExpired()
            responseJSON =
              error: responseError.access
              error_description: 'expired access_token'
            @unauthorizedRequestWithAccessToken(JSON.stringify(responseJSON))
          else
            # all is fine - pass it through the next layer
            @next()

      )

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

  # Handles unauthorized request which are done with an access token.
  # Sends a JSON response.
  #   
  # data - The error map
  #   error               - The error type (access_denied)
  #   error_description   - The description why the error occured
  unauthorizedRequestWithAccessToken:(data)->
    @responseHeader.setUnauthorized()
    @responseHeader.setJSON()
    @writeResponse(data,@res)

  # Handles any kind of occured errors.
  handleError:(options)->
    msg = if options.msg? then options.msg else "Something is missing"
    @responseHeader.setHtml()
    localVars = 
      errorMsg: msg
    compileOptions =
      template: "failure"
      locals: localVars
      cb: @writeResponse
      res: @res

    @templater.compile(compileOptions)

  
  # Writes any given data to the response object and sends it.
  # 
  # data - Any data (could be compiled HTML or JSON)
  # res  - An http response object.
  writeResponse:(data,res)->
    res.write(data)
    res.end()

# Export OAuthServer class to the global Node system.
global.OAuthServer = OAuthServer