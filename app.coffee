
###
Module dependencies.
###

express = require "express"
routes = require "./routes"
coffee = require "coffee-script"
pg = require "pg"
pg_url = process.env.HEROKU_POSTGRESQL_BRONZE_URL || "";
user = require "./routes/user"
assets = require "connect-assets"
ntwitter = require "ntwitter"
notifier = require "./notifier"
http = require "http"
path = require "path"
app = express()

db = (q)-> pg.connect pg_url, q
consumer_key = process.env.CONSUMER_KEY || ""
consumer_secret = process.env.CONSUMER_SECRET || ""

twitter = new ntwitter
  consumer_key: consumer_key
  consumer_secret: consumer_secret
  access_token_key: "1873580299-jljWnXJLQUD4XRuaHFM2iKq7F6sVIc05Y4Q2rHP"
  access_token_secret: "YipJAwYg7O10D562LwFMdBDaK4Jz3uJffhmPe4TFsYM"

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser("your secret here")
app.use express.session()
app.use app.router
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")
app.get "/", routes.index twitter, db
app.get "/index", routes.index twitter, db
app.get "/user/registor", user.registor twitter
app.get "/user/finish", user.finish twitter, db
app.get "/user/remove", user.remove
app.get "/user/confirm", user.confirm db
http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

# load clients
db (err, client, done)->
  return console.error 'error fetching client from pool', err if(err)
  client.query 'SELECT * from users', (err, result)->
    done()
    return console.error 'error running query', err if err
    notifier u.push_id, u.token, u.secret, u.regexp for u in result.rows

keepAlive = ()->
  setInterval (()->
      options =
        host: 'econotify.herokuapp.com',
        port: 80,
        path: '/'
      http.get(options, (res)->
        console.log "keepAlive"
      ).on 'error', (err)->
        console.error "Error : KeepAlive", err.message, err
  ), 30 * 60 * 1000

do keepAlive
