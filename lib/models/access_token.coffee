class AccessToken extends Mongoose.Base
  alias: 'acess_token'

  fields:
    access_token  : { type: String,   index: true }
    client_id     : { type: Mongoose.ObjectId, index: true }
    scope         : { type: String,   index: true }
    created_at    : { type: Date,     index: true }
    expires_at    : { type: Date,     index: true }