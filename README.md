Goodreads - Use NodeJS to tap into the Goodreads API
-----

This is a dead simple wrapper for the Goodreads API when using NodeJS. I've only exposed a few GR API functions so far but would be happy to entertain adding more if there's demand.

* Goodreads API: http://goodreads.com/api
* Github: https://github.com/bdickason/node-goodreads
* Twitter: [@bdickason](http://twitter.com/bdickason)
* E-mail: dickason@gmail.com

Installation
======
1. Install npm: `curl http://npmjs.org/install.sh | sh`
2. Grab this module from npm: `npm install goodreads`
3. Include it in your program:
 * Coffeescript: `goodreads = require 'goodreads'`
 * Javascript: `goodreads = require('goodreads');`
4. create a new instance of the Goodreads client:
 * Coffeescript: `gr = new goodreads.client { 'key': key, 'secret': secret }`
 * Javascript: `gr = new goodreads.client({ 'key': key, 'secret': secret });`
5. Go get a goodreads developer key/secret from http://www.goodreads.com/api/keys
6. _(optional)_ Add your key/secret to your environment variables so Nodejs can access them
 * Key: `export GOODREADS_KEY=yourkey`
 * Secret: `export GOODREADS_SECRET=yoursecret`
7. Try it out! Maybe do a `node examples/booklist.js` to get an idea how things work

Functions
=====
**showUser** - get user info with userName
* input - valid userName
* output - json (as callback)
* Example: `getShelves 'your_username', (json) ->`
* You must have created a username. You can do so [here](https://www.goodreads.com/user/edit).

**getShelves** - Get all shelves for a given user
* Input: userId
* Output: json (as callback)
* Example: `getShelves '4085451', (json) ->`

**getSingleShelf** - Get a specific list by ID
* Input: shelfOptions object with userID (required), shelf (required), page (optional), and per_page (optional) properties.
* Output: json (as callback)
* Example: `getSingleShelf {'userID': '4085451', 'shelf': 'web', 'page': 1, 'per_page': 200}, (json) ->`

**requestToken** - OAUTH: calls back an object with oauthToken, oauthTokenSecret, and the URL!
* Input: none
* Output: json `{ oauthToken: 'iu1iojij14141411414', oauthTokenSecret: 'j1kljklsajdklf132141', url: 'http://goodreads.com/blah'}`
* Example: `requestToken (callback) ->`

**processCallback** - expects: oauthToken, oauthTokenSecret, authorize (from the query string)
_Note: call this after requestToken!_
* Input: oauthToken, oauthTokenSecret, authorize
* Output: json `{ 'username': 'Brad Dickason', 'userid': '404168', 'success': 1, 'accessToken': '04ajdfkja', 'accessTokenSecret': 'i14k31j41jkm' }`
* Example: `processCallback oauthToken, oauthTokenSecret, params.query.authorize, (callback) ->`


_More to come!_


Help, I need an adult!
======
First step: Check out the `/examples` folder. It's decently documented.

If you're still having issues, you can submit them here: https://github.com/bdickason/node-goodreads/issues


Changelog
======
**v0.0.5** - Removed OAuth workarounds
* {`showUser`} method added - can get user information given their username.

**v0.0.2** - Removed OAuth workarounds
* OAuth Callback (`processCallback`) now properly returns an Access Token (`accessToken`) and Access Token Secret (`accessTokenSecret`)

**v0.0.1** - First release! Woohoo!!
* Added support getting a list of a user's shelves (`getShelves`)
* Added support for getting all books on a single shelf (`getSingleShelf`)
* Added support for an OAuth round trip via `requestToken` and `processCallback`
* Started this ugly manual
