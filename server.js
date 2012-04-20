var oauth_server = require('./index')
var http = require('http');
var connect = require('connect');


//var sample = connect.createServer();
//sample.use(connect.bodyParser());
//sample.use(oauth_server({database:"ovu_oauth_server"}));

connect.createServer().
  use(connect.bodyParser()).
  use(oauth_server({database:"ovu_oauth_server"})).listen(3001);
