class AccessGrant extends Mongoose.Base
  alias: 'access_grant'

  connection: oauth_connection

  # The following fields are defined:
  #
  # client_id   - A reference to the client which was granted for access.
  #               (This is not the ObjectId of a client.)
  # granted_at  - The date when the client was granted for access.
  # created_at  - The date this access grant was created.
  # expires_in  - Number of minutes the grant will expire (added to granted_at).
  # revoked     - The state if the access grant was revoked before.
  #               (No other access token request is possible after access
  #               grant was revoked.)
  fields:
    client_id           : { type: String, index: true }
    granted_at          : { type: Date,   index: true }
    created_at          : { type: Date,   index: true }
    expires_in          : { type: Number, index: true }
    revoked             : { type: Boolean, index: true, default: false}

  # Sets some default date values and calls parents class method.
  save:(cb)->
    @.set('granted_at':new Date())
    @.set('created_at':new Date())
    @.set('expires_in':10)
    super(cb)

  # Returns the authorization token which is basically the
  # MongoDb document id (this already very unique!)
  getAuthorizationCode:->
    @.get('_id')

  # Adds the expires_in minutes to the granted_at date.
  #
  # Returns the expire date of the access grant.
  getGrantAccessExpireDate:->
    expiresAtDate = @.getCreatedAt()
    expiresAtDate.setMinutes(expiresAtDate.getMinutes() + @.getExpiresIn())
    return expiresAtDate

module.exports = AccessGrant