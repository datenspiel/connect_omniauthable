###
Some basic OAuth variables which are used
later within the middleware
###

oauth_config = 
  authorizationUrlBase    : '/o/oauth2/auth'
  accessTokenExchangeURL  : ''
  denyClientAccessURL     : '/deny/access/:id/:state'
  grantClientAccessURL    : '/grant/access'
exports.oauth_config = oauth_config