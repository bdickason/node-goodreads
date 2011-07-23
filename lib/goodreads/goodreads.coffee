### Goodreads - Handles all connectivity to Goodreads API ###
### API Docs: http://www.goodreads.com/api ###

http = require 'http'
xml2js = require 'xml2js'
oauth = (require 'oauth').OAuth
redis = require 'redis'
sys = require 'sys'
## TODO REMOVE CFG + Redis
cfg = require '../../../booklist/config/config.js' # contains API keys, etc.

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

  # OAuth options
#  consumer: (options) ->
#    new oauth.OAuth 'http://goodreads.com/oauth/request_token', 'http://goodreads.com/oauth/access_token', options.key, options.secret, '1.0', options.callback, 'HMAC-SHA1'
#  consumer = ->
#    new oauth.OAuth 'http://goodreads.com/oauth/request_token', 'http://goodreads.com/oauth/access_token', @options.key, @options.secret, '1.0', @options.callback, 'HMAC-SHA1'

  # Start up redis to cache API stuff
  redis_client = redis.createClient cfg.REDIS_PORT, cfg.REDIS_HOSTNAME
  redis_client.on 'error', (err) ->
    console.log 'REDIS Error:' + err


  ### BOOKSHELVES ###

  # Get all shelves for a given user
  getShelves: (userId, callback) ->
    # Provide path to the API
    console.log 'Getting shelves ' + userId

    @options.path = 'http://www.goodreads.com/shelf/list.xml?user_id=' + userId + "&key=" + @options.key
  
    @getRequest callback
  
  # Get a specific list by ID
  getSingleShelf: (userId, listId, callback) ->
    # Provide path to the API
    console.log 'Getting list: ' + listId

    @options.path = 'http://www.goodreads.com/review/list/' + userId + '.xml?key=' + @options.key + '&shelf=' + listId
  
    @getRequest callback
  
  ### FRIENDS ###
  getFriends: (userId, req, res, callback) ->
    # Provide path to the API
    console.log 'Getting friends ' + userId

    @options.path = 'http://www.goodreads.com/friend/user/' + userId + '.xml?&key=' + @options.key
    console.log @options.path
    console.log req.session
    
    oa = new oauth @options.oauth_request_url, @options.oauth_access_url, @options.key, @options.secret, @options.oauth_version, @options.callback, @options.oauth_encryption

    oa.getProtectedResource @options.path, 'GET', req.session.goodreads_accessToken, req.session.goodreads_secret, (error, data, response) ->
      if error
        console.log oa
        callback 'Error getting OAuth request token : ' + JSON.stringify(error), 500
      else
        callback data
  
  ### OAUTH ###
  
  # requestToken - calls back an object with oauthToken, oauthTokenSecret, and the URL!
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
  processCallback: (oauthToken, oauthTokenSecret, authorize, callback) ->
    parser = new xml2js.Parser()
          
    oa = new oauth @options.oauth_request_url, @options.oauth_access_url, @options.key, @options.secret, @options.oauth_version, @options.callback, @options.oauth_encryption
    
    oa.getOAuthAccessToken oauthToken, oauthTokenSecret, authorize, (error, oauthAccessToken, oauthAccessTokenSecret, results) ->
      if error
        callback 'Error getting OAuth access token : ' + (sys.inspect error) + '[' + oauthAccessToken + '] [' + oauthAccessTokenSecret + '] [' + (sys.inspect results) + ']', 500
      else    
        oa.get 'http://www.goodreads.com/api/auth_user', oauthAccessToken, oauthAccessTokenSecret, (error, data, response) ->
          if error
            callback 'Error getting User ID : ' + (sys.inspect error), 500
          else
            parser.parseString(data)
  
    parser.on 'end', (result) ->    
      if result.user['@'].id != null
        callback { 'username': result.user.name, 'userid': result.user['@'].id, 'success': 1 }
      else
        callback 'Error: Invalid XML response received from Goodreads', 500
  
  ### API: 'GET' ###
  getRequest: (callback) ->
    _options = @options
    redis_client.get _options.path, (err, reply) ->
      if err
        console.log 'REDIS Error: ' + err
      else
        if reply
          callback JSON.parse(reply)
        else
          # Crap! Go grab it!

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
              
              redis_client.setex _options.path, cfg.REDIS_CACHE_TIME, JSON.stringify(result)
              callback result
          .end()
              
  clone = (obj) ->
    if obj != null || typeof(obj) != 'object'
      return obj

# Creates and returns a new Goodreads client.
module.exports = {
  client: (options) -> new Goodreads (options)
}