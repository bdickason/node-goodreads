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

# Initiate the client
goodreads_client = goodreads.client key, secret

http.createServer((req, res) ->
  res.writehead 200, {'Content-Type': 'text/plain'}
  res.end 'Hello World!\n'
).listen '3000', '127.0.0.1'

console.log 'Server running.'