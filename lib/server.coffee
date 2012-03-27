config  = require "./oauth_config"
qs      = require 'querystring'
path    = require 'path'
jade    = require 'jade'
fs      = require 'fs'
_       = require('./util/underscore_extension')._


Client = require("./models/client").Client

# Error response types as describe in draft-ietf-oauth-v2-23
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
      @checkAuthorizationParams(params)
  
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
            @unauthorizedRequest(params, responseError.access_denied)
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
  checkAuthorizationParams:(params)->
    required = ['client_id', 'response_type', 'redirect_uri','state']
    errors = []
    for parameter in required
      unless params.hasOwnProperty(parameter) or params[parameter] is ''
        errors.push({missing: parameter})

    unless _(params['redirect_uri']).isValidUrl()
      errors.push({errorMsg: 'invalid URL format for redirect_uri'})

    @handleError(errors) unless _.isEmpty(errors)

  # Writes any given data to the response object and sends it.
  # 
  # data - Any data (could be compiled HTML or JSON)
  # res  - An http response object.
  writeResponse:(data,res)->
    res.write(data)
    res.end()

# Export OAuthServer class to the global Node system.
global.OAuthServer = OAuthServer