(function() {
  var cfg, goodreads, http, key, onRequest, secret, url;
  cfg = require('../../booklist/config/config.js');
  /* Example!                                                    */
  /*   Grab a simple list of books from a random good reads user */
  /*                                                             */
  /* Note: Requires Goodreads Dev Keys (see below)               */
  /* Configuration                                               */
  /*   Get your keys at: http://www.goodreads.com/api/keys       */
  key = cfg.GOODREADS_KEY;
  secret = cfg.GOODREADS_SECRET;
  if (!key || !secret) {
    console.log('Edit this file and enter your Goodreads dev Key and Secret.');
    console.log('Get them at:  http://www.goodreads.com/api/keys');
    process.exit(1);
  }
  goodreads = require('../index.js');
  http = require('http');
  url = require('url');
  onRequest = function(req, res) {
    var callback, gr, pathname, tmp;
    pathname = url.parse(req.url).pathname;
    console.log('request for' + pathname + 'received');
    switch (pathname) {
      case '/shelves':
      case '/shelves/':
        gr = new goodreads.client({
          'key': key,
          'secret': secret
        });
        return gr.getShelves('4085451', function(json) {
          console.log(json);
          if (json) {
            res.write(JSON.stringify(json));
            return res.end();
          }
        });
      case '/shelf':
      case '/shelf/':
        gr = new goodreads.client({
          'key': key,
          'secret': secret
        });
        return gr.getSingleShelf('4085451', 'web', function(json) {
          console.log(json);
          if (json) {
            res.write(JSON.stringify(json));
            return res.end();
          }
        });
      case '/oauth':
      case '/oauth/':
        console.log('oauth');
        callback = '';
        gr = new goodreads.client({
          'key': key,
          'secret': secret
        });
        return tmp = gr.requestToken(callback, req, res);
      case '/callback':
        return console.log('callback');
      default:
        res.write('<html>Ok but you should enter a parameter or two.\n\n');
        res.write('How about...\n\n');
        res.write('<ul>');
        res.write('<li><A HREF=/shelves>Get a list of shelves</A></li>');
        res.write('<li><A HREF=/shelf>Get all books on a single shelf</A></li>');
        res.write('<li><em>Coming soon: OAuth!</em></li>');
        res.write('</ul></html>');
        return res.end();
    }
  };
  http.createServer(onRequest).listen(3000);
  console.log('server started');
}).call(this);
