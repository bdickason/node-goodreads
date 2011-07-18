# TODO remove this!
cfg = require '../../booklist/config/config.js' # contains API keys, etc.

### Example!                                                    ###
###   Grab a simple list of books from a random good reads user ###
###                                                             ###
### Note: Requires Goodreads Dev Keys (see below)               ###

### Configuration                                               ###
###   Get your keys at: http://www.goodreads.com/api/keys       ###
key = cfg.GOODREADS_KEY  ## Enter your key here to test! 
secret = cfg.GOODREADS_SECRET ## Enter your goodreads secret here to test!

if not key or not secret
  console.log 'Edit this file and enter your Goodreads dev Key and Secret.'
  console.log 'Get them at:  http://www.goodreads.com/api/keys'
  process.exit 1

# Require the client
goodreads = require '../index.js' # For you this looks like: require 'goodreads'
http = require 'http'
url = require 'url'

# excuse the clunkiness, I usually just require express and forget all this

onRequest = (req, res) ->
  pathname = url.parse(req.url).pathname
  console.log 'request for' + pathname + 'received'
  switch pathname
    # get a user's list of shelves
    when '/shelves', '/shelves/'
      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.getShelves '4085451', (json) ->
        # I would expect you won't be hardcoding these things :)
        console.log json
        if json
          # Received valid return from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()
    # Get a user's shelf  
    when '/shelf', '/shelf/'
      gr = new goodreads.client { 'key': key, 'secret': secret }
      gr.getSingleShelf '4085451', 'web', (json) ->
        # I would expect you won't be hardcoding these things :)
        console.log json
        if json
          # Received valid return from Goodreads
          res.write JSON.stringify json
          # Normally this is where you'd output a beautiful template or something!
          res.end()
    when '/oauth', '/oauth/'
      # handle oauth
      console.log 'oauth'

      callback = ''
      gr = new goodreads.client { 'key': key, 'secret': secret }
      tmp = gr.requestToken callback, req, res
      console.log tmp
      
    when '/callback'
      # handle callback
      console.log 'callback'
    else
      # ignore all other requests including annoying favicon.ico
      res.write '<html>Ok but you should enter a parameter or two.\n\n'
      res.write 'How about...\n\n'
      res.write '<ul>'
      res.write '<li><A HREF=/shelves>Get a list of shelves</A></li>'
      res.write '<li><A HREF=/shelf>Get all books on a single shelf</A></li>'
      res.write '<li><em>Coming soon: OAuth!</em></li>'
      res.write '</ul></html>'
      res.end()

http.createServer(onRequest).listen(3000);

console.log 'server started'