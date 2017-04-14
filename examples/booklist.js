/* jshint asi:true */
/* Example!                                                    */
/*   Grab a simple list of books from a random good reads user */
/*                                                             */
/* Note: Requires Goodreads Dev Keys (see below)               */

/* Configuration                                               */
/*   Get your keys at: http://www.goodreads.com/api/keys       */
let key = process.env.GOODREADS_KEY  //# Enter your key here to test!
let secret = process.env.GOODREADS_SECRET //# Enter your goodreads secret here to test!

if (!key || !secret) {
  console.log('You need to set your Goodreads dev Key and Secret!')
  console.log('---')
  console.log('1) Get them at:  http://www.goodreads.com/api/keys')
  console.log('2) Set your key environment variable with: export GOODREADS_KEY=yourkey')
  console.log('3) Set your secret environment variable with: export GOODREADS_SECRET=yoursecret')
  console.log('---')
  console.log('Having trouble? Ask me at @bdickason on Twitter.')
  process.exit(1)
}

// Require the client
const goodreads = require('../index.js').default // For you this looks like: require 'goodreads'
const http = require('http')
const url = require('url')

// excuse the clunkiness, I usually just require express and forget all this
let fakeSession = {}

let sample_user = 4085451

let onRequest = function(req, res) {
  let parse = url.parse(req.url, true)
  let { pathname } = parse, gr
  console.log(`request for [${pathname}] received`)
  switch (pathname) {

    // get a users info
    case '/user': case '/user/':
      let { username } = parse.query;
      console.log(`Getting user info for ${username}`);
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.showUser(username, function(json) {
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          // Normally this is where you'd output a beautiful template or something!
          return res.end();
        }
      });

    case '/series': case '/series/':
      console.log('Getting list of books from series 40650');
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.getSeries('40650', json => {});

    case '/author': case '/author/':
      console.log('Getting page 2 of list of books by author 18541');
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.getAuthor('18541', 2, json => {})

    // get a users info
    case '/search': case '/search/':
      let { q } = parse.query;
      console.log(`searching for book${q}`);
      return gr.searchBooks(q(function(json) {
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          // Normally this is where you'd output a beautiful template or something!
          return res.end();
        }
      })
      );

    // get a user's list of shelves
    case '/shelves': case '/shelves/':
      console.log(`Getting shelves ${sample_user}`);
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.getShelves(sample_user, function(json) {
        // I would expect you won't be hardcoding these things :)
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          // Normally this is where you'd output a beautiful template or something!
          return res.end();
        }
      });

    // Get a user's shelf
    case '/shelf': case '/shelf/':
      console.log('Getting list: web');
      gr = goodreads.client({ 'key': key, 'secret': secret });
      let shelfOptions = {'userID': sample_user, 'shelf': 'web', 'page': 1, 'per_page': 100};
      // I would expect you won't be hardcoding these things :)
      // There is a strange bug in /reviews/list. for per_page > 175, you get <error>forbidden</error>
      // I suspect it has to do with the processing time, so if you're getting the error, try reducing per_page
      if ("accessToken" in fakeSession) {
        shelfOptions.accessToken = fakeSession.accessToken;
        shelfOptions.accessTokenSecret = fakeSession.accessTokenSecret;
        console.log(shelfOptions);
      }
      return gr.getSingleShelf(shelfOptions, function(json) {
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          // Normally this is where you'd output a beautiful template or something!
          return res.end();
        }
      });

    // Get a protected resource
    case '/friends': case '/friends/':
      console.log(`Getting friends ${sample_user}`);
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.getFriends(sample_user, fakeSession.accessToken, fakeSession.accessTokenSecret, function(json) {
        // Yadda yadda put a real variable here etc.
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          return res.end();
        }
      });


    case '/oauth': case '/oauth/':
      // handle oauth

      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.requestToken().then((result) => {

        // log token and secret to our fake session
        fakeSession.oauthToken = result.oauthToken;
        fakeSession.oauthTokenSecret = result.oauthTokenSecret;

        // Redirect to the goodreads url!!
        res.writeHead('302', { 'Location': result.url });
        return res.end();
      });

    case '/callback':
      // handle Goodreads' callback

      // grab token and secret from our fake session
      let { oauthToken } = fakeSession;
      let { oauthTokenSecret } = fakeSession;

      // parse the querystring
      let params = url.parse(req.url, true);

      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.processCallback(oauthToken, oauthTokenSecret, params.query.authorize, function(callback) {
        fakeSession.accessToken = callback.accessToken;
        fakeSession.accessTokenSecret = callback.accessTokenSecret;
        res.write(JSON.stringify(callback));
        return res.end();
      });
        
    case '/authuser':
      console.log('Getting user authenticated using oauth');
      gr = goodreads.client({ 'key': key, 'secret': secret });
      return gr.showAuthUser(fakeSession.accessToken, fakeSession.accessTokenSecret, function(json) {
        if (json) {
          // Received valid response from Goodreads
          res.write(JSON.stringify(json));
          return res.end();
        }
      });

    default:
      // ignore all other requests including annoying favicon.ico
      res.write('<html>Ok but you should enter a parameter or two.\n\n');
      res.write('How about...\n\n');
      res.write('<ul>');
      res.write('<li><A HREF=/shelves>Get a list of shelves</A></li>');
      res.write('<li><A HREF=/shelf>Get all books on a single shelf</A></li>');
      res.write('<li><A HREF=/oauth>Connect to Goodreads via OAuth!</A></li>');
      res.write('</ul></html>');
      return res.end();
  }
};

http.createServer(onRequest).listen(3000);

console.log('server started on port 3000');
