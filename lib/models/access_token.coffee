require "./../util/secure_random"
class AccessToken extends Mongoose.Base
  @include Extensions.SecureRandom

  alias: 'acess_token'

  # The following fields are defined:
  #
  # access_token - The access 
  fields:
    access_token  : { type: String,   index: true }
    client_id     : { type: String,   index: true }
    scope         : { type: String,   index: true }
    created_at    : { type: Date,     index: true }
    expires_at    : { type: Date,     index: true }

  save:(cb)->
    @.set('access_token':@secureToken())
    super(cb)

exports.AccessToken = AccessToken