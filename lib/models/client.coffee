class Client extends Mongoose.Base
  alias: 'client'

  connection: oauth_connection

  fields:
    secret            : { type: String, index: true }
    client_id         : { type: String, index: true }
    redirect_uri      : { type: String, index: true }
    scopes            : { type: String, index: true }
    created_at        : { type: Date,   index: true }
    application_name  : { type: String, index: true }
    tokens_granted    : { type: Number, index: true }

module.exports = Client 