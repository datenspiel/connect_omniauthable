require "./../util/secure_random"
class AccessToken extends Mongoose.Base
  @include Extensions.SecureRandom

  alias: 'access_token'

  # The following fields are defined:
  #
  # access_token  - The access token which is used to access any data
  # client_id     - A reference to the client which was granted for access.
  #                 (This is not the ObjectId of a client.)
  # scope         - a namespace for which the access is granted.
  # created_at    - The date this access token was generated.
  # expires_at    - The date the access token expires. 
  fields:
    access_token  : { type: String,   index: true }
    client_id     : { type: String,   index: true }
    scope         : { type: String,   index: true }
    created_at    : { type: Date,     index: true }
    expires_at    : { type: Date,     index: true }

  # Generates and sets the access token before saving.
  save:(cb)->
    @.set('access_token':@secureToken())
    @.set('created_at': new Date())
    super(cb)

  isExpired:->
    false 

module.exports = AccessToken