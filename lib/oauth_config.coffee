###
Some basic OAuth variables which are used
later within the middleware
###

oauth_config = 
  authorizationUrlBase          : '/o/oauth2/auth'
  accessTokenRequestEndpointURL : '/o/oauth2/access_token'
  accessTokenExchangeURL        : ''
  denyClientAccessURL           : '/deny/access/:id/:state'
  grantClientAccessURL          : '/grant/access'
exports.oauth_config = oauth_config