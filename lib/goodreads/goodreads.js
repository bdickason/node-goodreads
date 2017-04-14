/* Goodreads - Handles all connectivity to Goodreads API */
/* API Docs: http://www.goodreads.com/api */

const http = require('http');
const xml2js = require('xml2js');
const oauth = require('oauth').OAuth;
const utils = require('utils');
import querystring from 'querystring';

var Goodreads = (() => {
  let clone;
  Goodreads = class Goodreads {
    static initClass() {
      clone = function(obj) {
        if ((obj !== null) || (typeof(obj) !== 'object')) {
          return obj;
        }
      };
    }

    /* CONFIG */

    // Default JSON options
    constructor(config) {
      this.options = {
        host: 'www.goodreads.com',
        port: 80,
        key: config.key,
        secret: config.secret,
        callback: config.callback || 'http://localhost:3000/callback',
        method: 'GET',
        path: '',
        oauth_request_url: 'https://goodreads.com/oauth/request_token',
        oauth_access_url: 'https://goodreads.com/oauth/access_token',
        oauth_version: '1.0A',
        oauth_encryption: 'HMAC-SHA1'
      };
      this.oauthAccessToken = '';
      this.oauthAcessTokenSecret = '';
      this.client = null;
    }

    configure(gr_key, gr_secret, gr_callback) {
      this.options.key = gr_key || this.options.key;
      this.options.secret = gr_secret || this.options.secret;
      this.options.callback = gr_callback || this.options.callback;
    }

    /* USER */

    // showUser - get user info with username
    // input - valid username
    // output - json (as callback)
    // Example: showUser 'your_username', (json) ->
    showUser(username, callback) {
      this.options.path = `https://www.goodreads.com/user/show.xml?key=${this.options.key}&username=${username}`;
      return this.getRequest(callback);
    }

    /* AUTHORS AND SERIES LIST OF BOOKS */

    // getAuthor - Get paginated list of books for a given author
    // Input: authorId, page
    // Output: json (as callback)
    // Example: getAuthor '18541', 2, (json) ->
    getAuthor(authorId, page, callback) {
      // Provide path to the API
      this.options.path = `https://www.goodreads.com/author/list/${authorId}?key=${this.options.key}&page=${page}`;
      return this.getRequest(callback);
    }

    // getSeries - Get all books in a given series
    // Input: seriesId
    // Output: json (as callback)
    // Example: getSeries '40650', (json) ->
    getSeries(seriesId, callback) {
      // Provide path to the API
      this.options.path = `https://www.goodreads.com/series/${seriesId}?key=${this.options.key}`;
      return this.getRequest(callback);
    }

    /* BOOKSHELVES */

    // getShelves - Get all shelves for a given user
    // Input: userId
    // Output: json (as callback)
    // Example: getShelves '4085451', (json) ->
    getShelves(userId, callback) {
      // Provide path to the API
      this.options.path = `http://www.goodreads.com/shelf/list.xml?user_id=${userId}&key=${this.options.key}`;

      return this.getRequest(callback);
    }

    // getSingleShelf - Get a specific list by ID
    // Input: userId, listId
    // Output: json (as callback)
    // Example: getSingleShelf '4085451', 'web', (json) ->
    getSingleShelf(shelfOptions, callback) {
      shelfOptions.key = this.options.key;
      let {userID} = shelfOptions;
      delete shelfOptions.userID;
      if ("accessToken" in shelfOptions) {
        this.oauthAccessToken = shelfOptions.accessToken;
        this.oauthAcessTokenSecret = shelfOptions.accessTokenSecret;
        delete shelfOptions.accessToken;
        delete shelfOptions.accessTokenSecret;
      }
      let queryOptions = querystring.stringify(shelfOptions);
      this.options.path = `http://www.goodreads.com/review/list/${userID}.xml?${querystring.stringify(shelfOptions)}`;
      if (this.oauthAccessToken) {
        return this.getProtectedRequest(result => callback(result.books[0].book));
      } else {
        return this.getRequest(result => callback(result.GoodreadsResponse.books[0].book));
      }
    }
        

    // getFriends - Get friends for a given user
    // Input: userId, accessToken, accessTokenSecret
    // Output: json (as callback) [{"$":{"start":"1","end":"30","total":"78"},"user":[{"id":["7324227"],"name":["Becca Christensen"],"link":["http://www.goodreads.com/user/show/7324227-becca-christensen"]...
    // Example: getSingleShelf '4085451', 'asjdfklac23414', '1234jkmk1m100', (json) ->
    getFriends(userId, accessToken, accessTokenSecret, callback) {
      // Provide path to the API
      this.options.path = `http://www.goodreads.com/friend/user/${userId}?format=xml`;
      this.oauthAccessToken = accessToken;
      this.oauthAcessTokenSecret = accessTokenSecret;
      return this.getProtectedRequest(result => callback(result.friends[0].user));
    }

    /* Search */
    // searchBooks
    // q: search value
    // Output: json (as callback)
    // Example: searchBooks 'Enders Game', (json) ->
    searchBooks(q, callback) {
      this.options.path = `https://www.goodreads.com/search/index.xml?key=${this.options.key}&q=${encodeURI(q)}`;
      return this.getRequest(callback);
    }


    /* OAUTH */

    // requestToken - calls back an object with oauthToken, oauthTokenSecret, and the URL!
    // Input: none
    // Output: json { oauthToken: 'iu1iojij14141411414', oauthTokenSecret: 'j1kljklsajdklf132141', url: 'http://goodreads.com/blah'}
    // Example: requestToken (callback) ->
    requestToken() {
    	return new Promise((resolve, reject) => {
    		let oa = new oauth(this.options.oauth_request_url, this.options.oauth_access_url, this.options.key, this.options.secret, this.options.oauth_version, this.options.callback, this.options.oauth_encryption)

	      oa.getOAuthRequestToken((error, oauthToken, oauthTokenSecret, results) => {
	        if (error) {
	          console.error(error)
	          return reject(`Error getting OAuth request token : ${JSON.stringify(error)}`, 500);
	        } else {
	          // assemble goodreads URL
	          let url = `https://goodreads.com/oauth/authorize?oauth_token=${oauthToken}&oauth_callback=${oa._authorize_callback}`
	          return resolve({oauthToken, oauthTokenSecret, url})
	      	}
	      })
    	})
    }

    // processCallback - expects: oauthToken, oauthTokenSecret, authorize (from the query string)
    // Note: call this after requestToken!
    // Input: oauthToken, oauthTokenSecret, authorize
    // Output: json { 'username': 'Brad Dickason', 'userid': '404168', 'success': 1, 'accessToken': '04ajdfkja', 'accessTokenSecret': 'i14k31j41jkm' }
    // Example: processCallback oauthToken, oauthTokenSecret, params.query.authorize, (callback) ->

    processCallback(oauthToken, oauthTokenSecret, authorize, callback) {

      let oa = new oauth(this.options.oauth_request_url, this.options.oauth_access_url, this.options.key, this.options.secret, this.options.oauth_version, this.options.callback, this.options.oauth_encryption)

      return oa.getOAuthAccessToken(oauthToken, oauthTokenSecret, authorize, (error, oauthAccessToken, oauthAccessTokenSecret, results) => {
        let parser = new xml2js.Parser()
        if (error) {
          callback(`Error getting OAuth access token : ${utils.inspect(error)}[${oauthAccessToken}] [${oauthAccessTokenSecret}] [${utils.inspect(results)}]`, 500)
        } else {
          oa.get('http://www.goodreads.com/api/auth_user', oauthAccessToken, oauthAccessTokenSecret, function(error, data, response) {
            if (error) {
              return callback(`Error getting User ID : ${utils.inspect(error)}`, 500)
            } else {
              return parser.parseString(data)
            }
          })
        }

        return parser.on('end', function(result) {
          result = result.GoodreadsResponse // Object is now getting this in front of the object

          if (result.user[0]['$'].id !== null) {
            return callback({ 'username': result.user[0].name[0], 'userid': result.user[0]['$'].id, 'success': 1, 'accessToken': oauthAccessToken, 'accessTokenSecret': oauthAccessTokenSecret })
          } else {
            return callback('Error: Invalid XML response received from Goodreads', 500)
          }
        })
      })
    }
          
    // showAuthUser - get the user currently authenticated via oauth (for testing)
    // Note: call only after oauth
    // Input: oauthAccessToken, oauthAccessTokenSecret
    // Output: json {"$":{"id":"4085451"},"name":["your name"],"link":["http://www.goodreads.com/user/show/4085451-yourname?utm_medium=api"]}
    // Example: showAuthUser fakeSession.accessToken, fakeSession.accessTokenSecret, (json) ->
  
    showAuthUser(accessToken, accessTokenSecret, callback) {
      let oa = new oauth(this.options.oauth_request_url, this.options.oauth_access_url, this.options.key, this.options.secret, this.options.oauth_version, this.options.callback, this.options.oauth_encryption)
      let parser = new xml2js.Parser()
      oa.get("http://www.goodreads.com/api/auth_user", accessToken, accessTokenSecret, function(error, data, response) {
        if (error) {
          return callback(`Error getting OAuth request token : ${JSON.stringify(error)}`, 500)
        } else {
          return parser.parseString(data)
        }
      })
      return parser.on('end', function(result) {
        result = result.GoodreadsResponse // Object is now getting this in front of the object

        if (result.user[0] !== null) {
          return callback(result.user[0])
        } else {
          return callback('Error: Invalid XML response received from Goodreads', 500)
        }
      })
    }

    /* API: 'GET' */
    getRequest(callback) {
      let _options = this.options

      let tmp = []  // Russ at the NYC NodeJS Meetup said array push is faster

      let parser = new xml2js.Parser()

      return http.request(_options, function(res) {
        res.setEncoding('utf8')

        res.on('data', chunk => tmp.push(chunk))  // Throw the chunk into the array

        res.on('end', function(e) {
          let body = tmp.join('')
          return parser.parseString(body)
        })

        return parser.on('end', result => callback(result));}).end();
    }
   
    getProtectedRequest(callback) {
      let oa = new oauth(this.options.oauth_request_url, this.options.oauth_access_url, this.options.key, this.options.secret, this.options.oauth_version, this.options.callback, this.options.oauth_encryption);
      let parser = new xml2js.Parser();
      oa.get(this.options.path, this.oauthAccessToken, this.oauthAcessTokenSecret, function(error, data, response) {
        if (error) {
          return callback(`Error getting OAuth request token : ${JSON.stringify(error)}`, 500);
        } else {
          return parser.parseString(data);
        }
      });
      return parser.on('end', function(result) {
        result = result.GoodreadsResponse; // Object is now getting this in front of the object
        if (result !== null) {
          return callback(result);
        } else {
          return callback('Error: Invalid XML response received from Goodreads', 500);
        }
      });
    }
  };
  Goodreads.initClass();
  return Goodreads;
})();

// Creates and returns a new Goodreads client.
export default {
  client(options) { return new Goodreads((options)); }
};
