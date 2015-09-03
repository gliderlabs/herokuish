var express = require('express');
var app = express();

app.get('/', function(req, res){
  res.send("nodejs-express\n");
});

/* Use PORT environment variable if it exists */
var port = process.env.PORT || 5000;
server = app.listen(port);

process.on( "SIGINT", function() {
  console.log('CLOSING [SIGINT]');
  process.exit();
} );

process.on( "SIGTERM", function() {
  console.log('CLOSING [SIGTERM]');
  process.exit();
} );

console.log('Server listening on port %d in %s mode', server.address().port, app.settings.env);
