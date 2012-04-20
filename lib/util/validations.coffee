_ = require('./underscore_extension')._

Extensions.Validations = 
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

    unless _.isEmpty(errors)
      @handleError(errors) 
    else
      return true
      
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
    unless params['grant_type'] == 'authorization_code'
      errors.push({error: 'Invalid type for grant_type.'})

    unless _.isEmpty(errors)
      @handleError(errors, {type: "json"}) 
    else
      return
