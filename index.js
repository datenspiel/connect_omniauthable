require('coffee-script');
//require('./test');
//
var http = require('http');
var connect = require('connect');
//
var oauth_server = require("./lib/omni");
//
var mongo = require('mongoose');

oauth_server.oauth_config = {
  oauth_endpoint : "/"
}

console.log(oauth_server);

var sample = connect.createServer();
sample.use(connect.bodyParser());
sample.use(oauth_server.omni_auth("neidhammel"));

http.createServer(sample).listen(3001);

exports.omni_server = oauth_server;//