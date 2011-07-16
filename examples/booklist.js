(function() {
  /* Example!                                                    */
  /*   Grab a simple list of books from a random good reads user */
  /*                                                             */
  /* Note: Requires Goodreads Dev Keys (see below)               */
  /* Configuration                                               */
  /*   Get your keys at: http://www.goodreads.com/api/keys       */  var goodreads, goodreads_client, http, key, secret;
  key = 'aksdjfa';
  secret = 'kljlsajf';
  if (!key || !secret) {
    console.log('Edit this file and enter your Goodreads dev Key and Secret.');
    console.log('Get them at:  http://www.goodreads.com/api/keys');
    process.exit(1);
  }
  goodreads = require('../index.js');
  http = require('http');
  goodreads_client = goodreads.client(key, secret);
  http.createServer(function(req, res) {
    res.writehead(200, {
      'Content-Type': 'text/plain'
    });
    return res.end('Hello World!\n');
  }).listen('3000', '127.0.0.1');
  console.log('Server running.');
}).call(this);
