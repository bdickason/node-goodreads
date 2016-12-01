### Example!                                                    ###
###   Grab a simple list of books from a random good reads user ###
###                                                             ###
### Note: Requires Goodreads Dev Keys (see below)               ###

### Configuration                                               ###
###   Get your keys at: http://www.goodreads.com/api/keys       ###
key = process.env.GOODREADS_KEY  ## Enter your key here to test!
secret = process.env.GOODREADS_SECRET ## Enter your goodreads secret here to test!

if not key or not secret
  console.log 'You need to set your Goodreads dev Key and Secret!'
  console.log '---'
  console.log '1) Get them at:  http://www.goodreads.com/api/keys'
  console.log '2) Set your key environment variable with: export GOODREADS_KEY=yourkey'
  console.log '3) Set your secret environment variable with: export GOODREADS_SECRET=yoursecret'
  console.log '---'
  console.log 'Having trouble? Ask me at @bdickason on Twitter.'
  process.exit 1

# Require the client
goodreads = require '../index.js' # For you this looks like: require 'goodreads'
http = require 'http'
url = require 'url'

# excuse the clunkiness, I usually just require express and forget all this
fakeSession = { }

onRequest = (req, res) ->
  parse = user.parse(req.url, true)
  pathname = parse.pathname
  console.log 'request for [' + pathname + '] received'
  switch pathname

    # get a users info
    when '/user', '/user/'
      username = parse.query.username
      console.log 'Getting user info' + username
      gr.showUser username, (json) ->
        if json
          # Received valid response from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()

    # get a users info
    when '/search', '/search/'
      q = parse.query.q
      console.log 'searching for book' + q 
      gr.searchBooksq, (json) ->
        if json
          # Received valid response from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()

    # get a user's list of shelves
    when '/shelves', '/shelves/'
      console.log 'Getting shelves ' + '4085451'
      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.getShelves '4085451', (json) ->
        # I would expect you won't be hardcoding these things :)
        if json
          # Received valid response from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()

    # Get a user's shelf
    when '/shelf', '/shelf/'
      console.log 'Getting list: ' + 'web'
      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.getSingleShelf {'userID': '4085451', 'shelf': 'web', 'page': 1, 'per_page': 200}, (json) ->
        # I would expect you won't be hardcoding these things :)
        if json
          # Received valid response from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()

    # Get a protected resource
    when '/friends', '/friends/'
      console.log 'Getting friends ' + '4085451'
      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.getFriends '4085451', (json) ->
        # Yadda yadda put a real variable here etc.
        if json
          # Received valid response from Goodreads
          res.write JSON.stringify json
          res.end()


    when '/oauth', '/oauth/'
      # handle oauth

      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.requestToken (callback) ->

        # log token and secret to our fake session
        fakeSession.oauthToken = callback.oauthToken
        fakeSession.oauthTokenSecret = callback.oauthTokenSecret

        # Redirect to the goodreads url!!
        res.writeHead '302', { 'Location': callback.url }
        res.end()

    when '/callback'
      # handle Goodreads' callback

      # grab token and secret from our fake session
      oauthToken = fakeSession.oauthToken
      oauthTokenSecret = fakeSession.oauthTokenSecret

      # parse the querystring
      params = url.parse req.url, true

      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.processCallback oauthToken, oauthTokenSecret, params.query.authorize, (callback) ->
        res.write JSON.stringify callback
        res.end()

    else
      # ignore all other requests including annoying favicon.ico
      res.write '<html>Ok but you should enter a parameter or two.\n\n'
      res.write 'How about...\n\n'
      res.write '<ul>'
      res.write '<li><A HREF=/shelves>Get a list of shelves</A></li>'
      res.write '<li><A HREF=/shelf>Get all books on a single shelf</A></li>'
      res.write '<li><A HREF=/oauth>Connect to Goodreads via OAuth!</A></li>'
      res.write '</ul></html>'
      res.end()

http.createServer(onRequest).listen(3000);

console.log 'server started on port 3000'
