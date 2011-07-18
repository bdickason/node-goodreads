### Goodreads - Handles all connectivity to Goodreads API ###
### API Docs: http://www.goodreads.com/api ###

http = require 'http'
xml2js = require 'xml2js'
oauth = require 'oauth'
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
    }
    @client = null
  
  configure: (gr_key, gr_secret, gr_callback) ->
    @options.key = gr_key or @options.key
    @options.secret = gr_secret or @options.secret
    @options.callback = gr_callback or @options.callback

  # OAuth options
  consumer: (options) ->
    new oauth.OAuth 'http://goodreads.com/oauth/request_token', 'http://goodreads.com/oauth/access_token', options.key, options.secret, '1.0', options.callback, 'HMAC-SHA1'
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
    
    consumer().getProtectedResource @options.path, 'GET', req.session.goodreads_accessToken, req.session.goodreads_secret, (error, data, response) ->
      if error
        console.log consumer()
        callback 'Error getting OAuth request token : ' + JSON.stringify(error), 500
      else
        callback data
  
  ### OAUTH ###
  requestToken: (callback, req, res) ->
    console.log @options  
    
    @consumer(@options).getOAuthRequestToken (error, oauthToken, oauthTokenSecret, results) -> 
      if error
        console.log error
        callback 'Error getting OAuth request token : ' + JSON.stringify(error), 500
      else
        console.log 
        
        # req.session.oauthRequestToken = oauthToken
        # req.session.oauthRequestTokenSecret = oauthTokenSecret

        url = 'https://goodreads.com/oauth/authorize?oauth_token=' + oauthToken + '&oauth_callback=' + @_authorize_callback
        return { 'oauthToken': oauthToken, 'oauthTokenSecret': oauthTokenSecret, 'url': url}

  callback: (callback, req, res) ->
    parser = new xml2js.Parser()
  
    consumer().getOAuthAccessToken req.session.oauthRequestToken, req.session.oauthRequestTokenSecret, req.query.oauth_verifier, (error, oauthAccessToken, oauthAccessTokenSecret, results) ->
      if error
        res.send 'Error getting OAuth access token : ' + (sys.inspect error) + '[' + oauthAccessToken + '] [' + oauthAccessTokenSecret + '] [' + (sys.inspect results) + ']', 500
      else
        req.session.goodreads_accessToken = oauthAccessToken
        req.session.goodreads_secret = oauthAccessTokenSecret
        consumer().get 'http://www.goodreads.com/api/auth_user', req.session.goodreads_accessToken, req.session.goodreads_secret, (error, data, response) ->
          if error
            res.send 'Error getting User ID : ' + (sys.inspect error), 500
          else
            parser.parseString(data)
  
    parser.on 'end', (result) ->
      req.session.goodreads_name = result.user.name
      req.session.goodreads_id = result.user['@'].id
      req.session.goodreads_auth = 1

      console.log req.session.goodreads_name + 'signed in with user ID: ' + req.session.goodreads_id + '\n'
      res.redirect '/'
      
      if req.session.goodreads_id != null
        users = new Users
        users.addUser(req.session.goodreads_id, req.session.goodreads_name, callback)
        console.log 'finished saving to the db'
      
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