### Example!                                                    ###
###   Grab a simple list of books from a random good reads user ###
###                                                             ###
### Note: Requires Goodreads Dev Keys (see below)               ###

### Configuration                                               ###
###   Get your keys at: http://www.goodreads.com/api/keys       ###
key = 'aksdjfa'  ## Enter your key here to test! 
secret = 'kljlsajf' ## Enter your goodreads secret here to test!

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
    when '/oauth', '/oauth/'
      # handle oauth
      console.log 'oauth!'
    when '/list', '/list/'
      gr = new goodreads.client key, secret
      gr.getSingleList '4085451', 'web', (json) ->
        # I would expect you won't be hardcoding these things :)
        console.log json
        if json
          # Received valid return from Goodreads
          res.write json
          res.end()
    else
      # ignore all other requests including annoying favicon.ico
      res.write 'else'
      res.end()

http.createServer(onRequest).listen(3000);

console.log 'server started'