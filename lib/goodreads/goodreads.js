(function() {
  /* Goodreads - Handles all connectivity to Goodreads API */
  /* API Docs: http://www.goodreads.com/api */  var Goodreads, cfg, http, oauth, redis, sys, xml2js;
  http = require('http');
  xml2js = require('xml2js');
  oauth = require('oauth');
  redis = require('redis');
  sys = require('sys');
  cfg = require('../../../booklist/config/config.js');
  Goodreads = (function() {
    /* CONFIG */    var clone, consumer, redis_client;
    function Goodreads(config) {
      this.options = {
        host: 'www.goodreads.com',
        port: 80,
        key: config.key,
        secret: config.secret,
        callback: config.callback || 'http://localhost:3000/callback',
        method: 'GET',
        path: ''
      };
      this.client = null;
    }
    Goodreads.prototype.configure = function(gr_key, gr_secret, gr_callback) {
      this.options.key = gr_key || this.options.key;
      this.options.secret = gr_secret || this.options.secret;
      return this.options.callback = gr_callback || this.options.callback;
    };
    consumer = function() {
      return new oauth.OAuth('http://goodreads.com/oauth/request_token', 'http://goodreads.com/oauth/access_token', this.options.key, this.options.secret, '1.0', this.options_callback, 'HMAC-SHA1');
    };
    redis_client = redis.createClient(cfg.REDIS_PORT, cfg.REDIS_HOSTNAME);
    redis_client.on('error', function(err) {
      return console.log('REDIS Error:' + err);
    });
    /* BOOKSHELVES */
    Goodreads.prototype.getShelves = function(userId, callback) {
      console.log('Getting shelves ' + userId);
      this.options.path = 'http://www.goodreads.com/shelf/list.xml?user_id=' + userId + "&key=" + this.options.key;
      return this.getRequest(callback);
    };
    Goodreads.prototype.getSingleList = function(userId, listId, callback) {
      console.log('Getting list: ' + listId);
      this.options.path = 'http://www.goodreads.com/review/list/' + userId + '.xml?key=' + this.options.key + '&shelf=' + listId;
      return this.getRequest(callback);
    };
    /* FRIENDS */
    Goodreads.prototype.getFriends = function(userId, req, res, callback) {
      console.log('Getting friends ' + userId);
      this.options.path = 'http://www.goodreads.com/friend/user/' + userId + '.xml?&key=' + this.options.key;
      console.log(this.options.path);
      console.log(req.session);
      return consumer().getProtectedResource(this.options.path, 'GET', req.session.goodreads_accessToken, req.session.goodreads_secret, function(error, data, response) {
        if (error) {
          console.log(consumer());
          return callback('Error getting OAuth request token : ' + JSON.stringify(error), 500);
        } else {
          return callback(data);
        }
      });
    };
    /* OAUTH */
    Goodreads.prototype.requestToken = function(callback, req, res) {
      return consumer().getOAuthRequestToken(function(error, oauthToken, oauthTokenSecret, results) {
        if (error) {
          console.log(consumer());
          return callback('Error getting OAuth request token : ' + JSON.stringify(error), 500);
        } else {
          req.session.oauthRequestToken = oauthToken;
          req.session.oauthRequestTokenSecret = oauthTokenSecret;
          return res.redirect('https://goodreads.com/oauth/authorize?oauth_token=' + req.session.oauthRequestToken + '&oauth_callback=' + consumer()._authorize_callback);
        }
      });
    };
    Goodreads.prototype.callback = function(callback, req, res) {
      var parser;
      parser = new xml2js.Parser();
      consumer().getOAuthAccessToken(req.session.oauthRequestToken, req.session.oauthRequestTokenSecret, req.query.oauth_verifier, function(error, oauthAccessToken, oauthAccessTokenSecret, results) {
        if (error) {
          return res.send('Error getting OAuth access token : ' + (sys.inspect(error)) + '[' + oauthAccessToken + '] [' + oauthAccessTokenSecret + '] [' + (sys.inspect(results)) + ']', 500);
        } else {
          req.session.goodreads_accessToken = oauthAccessToken;
          req.session.goodreads_secret = oauthAccessTokenSecret;
          return consumer().get('http://www.goodreads.com/api/auth_user', req.session.goodreads_accessToken, req.session.goodreads_secret, function(error, data, response) {
            if (error) {
              return res.send('Error getting User ID : ' + (sys.inspect(error)), 500);
            } else {
              return parser.parseString(data);
            }
          });
        }
      });
      return parser.on('end', function(result) {
        var users;
        req.session.goodreads_name = result.user.name;
        req.session.goodreads_id = result.user['@'].id;
        req.session.goodreads_auth = 1;
        console.log(req.session.goodreads_name + 'signed in with user ID: ' + req.session.goodreads_id + '\n');
        res.redirect('/');
        if (req.session.goodreads_id !== null) {
          users = new Users;
          users.addUser(req.session.goodreads_id, req.session.goodreads_name, callback);
          return console.log('finished saving to the db');
        }
      });
    };
    /* API: 'GET' */
    Goodreads.prototype.getRequest = function(callback) {
      var _options;
      _options = this.options;
      return redis_client.get(_options.path, function(err, reply) {
        var parser, tmp;
        if (err) {
          return console.log('REDIS Error: ' + err);
        } else {
          if (reply) {
            return callback(JSON.parse(reply));
          } else {
            tmp = [];
            parser = new xml2js.Parser();
            return http.request(_options, function(res) {
              res.setEncoding('utf8');
              res.on('data', function(chunk) {
                return tmp.push(chunk);
              });
              res.on('end', function(e) {
                var body;
                body = tmp.join('');
                return parser.parseString(body);
              });
              return parser.on('end', function(result) {
                redis_client.setex(_options.path, cfg.REDIS_CACHE_TIME, JSON.stringify(result));
                return callback(result);
              });
            }).end();
          }
        }
      });
    };
    clone = function(obj) {
      if (obj !== null || typeof obj !== 'object') {
        return obj;
      }
    };
    return Goodreads;
  })();
  module.exports = {
    client: function(options) {
      return new Goodreads(options);
    }
  };
}).call(this);
