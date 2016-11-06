### Goodreads - Handles all connectivity to Goodreads API ###
### API Docs: http://www.goodreads.com/api ###

http = require 'http'
xml2js = require 'xml2js'
oauth = (require 'oauth').OAuth
sys = require 'sys'
querystring = require 'querystring'

class Goodreads

  ### CONFIG ###

  # Default JSON options
  constructor: (config) ->
    @options = {
      host: 'www.goodreads.com',
      port: 80,
      key: config.key,
      secret: config.secret,
      callback: config.callback or 'http://localhost:3000/callback',
      method: 'GET',
      path: ''
      oauth_request_url: 'http://goodreads.com/oauth/request_token'
      oauth_access_url: 'http://goodreads.com/oauth/access_token'
      oauth_version: '1.0'
      oauth_encryption: 'HMAC-SHA1'
    }
    @oauthAccessToken = ''
    @oauthAcessTokenSecret = ''
    @client = null

  configure: (gr_key, gr_secret, gr_callback) ->
    @options.key = gr_key or @options.key
    @options.secret = gr_secret or @options.secret
    @options.callback = gr_callback or @options.callback

  ### USER ###

  # showUser - get user info with username
  # input - valid username
  # output - json (as callback)
  # Example: getShelves 'your_username', (json) ->
  showUser: (username, callback) ->
    @options.path = "https://www.goodreads.com/user/show.xml?key=#{@options.key}&username=#{username}"
    @getRequest callback

  ### BOOKSHELVES ###

  # getShelves - Get all shelves for a given user
  # Input: userId
  # Output: json (as callback)
  # Example: getShelves '4085451', (json) ->
  getShelves: (userId, callback) ->
    # Provide path to the API
    @options.path = 'http://www.goodreads.com/shelf/list.xml?user_id=' + userId + "&key=" + @options.key

    @getRequest callback

  # getSingleShelf - Get a specific list by ID
  # Input: userId, listId
  # Output: json (as callback)
  # Example: getSingleShelf '4085451', 'web', (json) ->
  getSingleShelf: (shelfOptions, callback) ->
    shelfOptions.key = @options.key
    queryOptions = querystring.stringify(shelfOptions)
    userID = shelfOptions.userID
    delete shelfOptions.userID
    @options.path = 'http://www.goodreads.com/review/list/' + userID + '.xml?' + querystring.stringify(shelfOptions)
    @getRequest callback

  ### NOTE: Not Working Yet!!!! ###
  # getFriends - Get friends for a given user
  # Input: userId, accessToken, accessTokenSecret
  # Output: json (as callback)
  # Example: getSingleShelf '4085451', 'asjdfklac23414', '1234jkmk1m100', (json) ->
  getFriends: (userId, accessToken, accessTokenSecret, callback) ->
    # Provide path to the API
    @options.path = 'http://www.goodreads.com/friend/user/' + userId + '.xml?&key=' + @options.key

    oa = new oauth @options.oauth_request_url, @options.oauth_access_url, @options.key, @options.secret, @options.oauth_version, @options.callback, @options.oauth_encryption

    oa.getProtectedResource @options.path, 'GET', accessToken, accessTokenSecret, (error, data, response) ->
      if error
        callback 'Error getting OAuth request token : ' + JSON.stringify(error), 500
      else
        callback data


  ### Search ###
  # searchBooks
  # q: search value
  # Output: json (as callback)
  # Example: searchBooks 'Enders Game', (json) ->
  searchBooks: (q, callback) ->
    @options.path = "https://www.goodreads.com/search/index.xml?key=#{@options.key}&q=#{encodeURI(q)}"
    @getRequest callback



  ### OAUTH ###

  # requestToken - calls back an object with oauthToken, oauthTokenSecret, and the URL!
  # Input: none
  # Output: json { oauthToken: 'iu1iojij14141411414', oauthTokenSecret: 'j1kljklsajdklf132141', url: 'http://goodreads.com/blah'}
  # Example: requestToken (callback) ->
  requestToken: (callback) ->
    oa = new oauth @options.oauth_request_url, @options.oauth_access_url, @options.key, @options.secret, @options.oauth_version, @options.callback, @options.oauth_encryption

    oa.getOAuthRequestToken (error, oauthToken, oauthTokenSecret, results) ->
      if error
        console.log error
        callback 'Error getting OAuth request token : ' + JSON.stringify(error), 500
      else
        # assemble goodreads URL
        url = 'https://goodreads.com/oauth/authorize?oauth_token=' + oauthToken + '&oauth_callback=' + oa._authorize_callback

        callback { oauthToken, oauthTokenSecret, url }

  # processCallback - expects: oauthToken, oauthTokenSecret, authorize (from the query string)
  # Note: call this after requestToken!
  # Input: oauthToken, oauthTokenSecret, authorize
  # Output: json { 'username': 'Brad Dickason', 'userid': '404168', 'success': 1, 'accessToken': '04ajdfkja', 'accessTokenSecret': 'i14k31j41jkm' }
  # Example: processCallback oauthToken, oauthTokenSecret, params.query.authorize, (callback) ->

  processCallback: (oauthToken, oauthTokenSecret, authorize, callback) ->

    oa = new oauth @options.oauth_request_url, @options.oauth_access_url, @options.key, @options.secret, @options.oauth_version, @options.callback, @options.oauth_encryption

    oa.getOAuthAccessToken oauthToken, oauthTokenSecret, authorize, (error, oauthAccessToken, oauthAccessTokenSecret, results) ->
      parser = new xml2js.Parser()
      if error
        callback 'Error getting OAuth access token : ' + (sys.inspect error) + '[' + oauthAccessToken + '] [' + oauthAccessTokenSecret + '] [' + (sys.inspect results) + ']', 500
      else
        oa.get 'http://www.goodreads.com/api/auth_user', oauthAccessToken, oauthAccessTokenSecret, (error, data, response) ->
          if error
            callback 'Error getting User ID : ' + (sys.inspect error), 500
          else
            parser.parseString(data)

      parser.on 'end', (result) ->
        result = result.GoodreadsResponse # Object is now getting this in front of the object

        if result.user[0]['$'].id != null
          callback { 'username': result.user.name, 'userid': result.user[0]['$'].id, 'success': 1, 'accessToken': oauthAccessToken, 'accessTokenSecret': oauthAccessTokenSecret }
        else
          callback 'Error: Invalid XML response received from Goodreads', 500

  ### API: 'GET' ###
  getRequest: (callback) ->
    _options = @options

    tmp = []  # Russ at the NYC NodeJS Meetup said array push is faster

    parser = new xml2js.Parser()

    http.request _options, (res) ->
      res.setEncoding 'utf8'

      res.on 'data', (chunk) ->
        tmp.push chunk  # Throw the chunk into the array

      res.on 'end', (e) ->
        body = tmp.join('')
        parser.parseString body

      parser.on 'end', (result) ->
        callback result

    .end()

  clone = (obj) ->
    if obj != null || typeof(obj) != 'object'
      return obj

# Creates and returns a new Goodreads client.
module.exports = {
  client: (options) -> new Goodreads (options)
}
