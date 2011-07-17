(function() {
  /* Example!                                                    */
  /*   Grab a simple list of books from a random good reads user */
  /*                                                             */
  /* Note: Requires Goodreads Dev Keys (see below)               */
  /* Configuration                                               */
  /*   Get your keys at: http://www.goodreads.com/api/keys       */  var goodreads, http, key, onRequest, secret, url;
  key = 'aksdjfa';
  secret = 'kljlsajf';
  if (!key || !secret) {
    console.log('Edit this file and enter your Goodreads dev Key and Secret.');
    console.log('Get them at:  http://www.goodreads.com/api/keys');
    process.exit(1);
  }
  goodreads = require('../index.js');
  http = require('http');
  url = require('url');
  onRequest = function(req, res) {
    var gr, pathname;
    pathname = url.parse(req.url).pathname;
    console.log('request for' + pathname + 'received');
    switch (pathname) {
      case '/oauth':
      case '/oauth/':
        return console.log('oauth!');
      case '/list':
      case '/list/':
        gr = new goodreads.client(key, secret);
        return gr.getSingleList('4085451', 'web', function(json) {
          console.log(json);
          if (json) {
            res.write(json);
            return res.end();
          }
        });
      default:
        res.write('else');
        return res.end();
    }
  };
  http.createServer(onRequest).listen(3000);
  console.log('server started');
}).call(this);
