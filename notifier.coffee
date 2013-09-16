
ntwitter = require "ntwitter"
gcm = require "node-gcm"
gcm_api_key = process.env.GCM_API_KEY || ""
sender = new gcm.Sender gcm_api_key
consumer_key = process.env.CONSUMER_KEY || ""
consumer_secret = process.env.CONSUMER_SECRET || ""

notifier = (push_id, token, secret, regex)->
  twitter = new ntwitter
    consumer_key: consumer_key
    consumer_secret: consumer_secret
    access_token_key: token
    access_token_secret: secret

  socket = null
  restart = ->
    notifier(push_id, token, secret, regex)
    socket.destroy()


  compiled_regex = new RegExp regex
  twitter.stream 'user', (stream)->
    socket = stream
    setTimeout ()->
      restart()
    , 1000*60*60
    stream.on 'data', (data)->
      if data.user && compiled_regex.test data.text
        send_notify push_id, data.id_str, data.text, data.user.name+" ("+data.user.screen_name+")", data.user.profile_image_url
    stream.on 'end', (response)->
      restart()
    stream.on 'error', (e)->
      console.log "error"
      console.error e
    stream.on 'destroy', (response)->
      restart()

send_notify = (push_id, id, title, message, icon)->
  message = new gcm.Message
    collapseKey: id.toString()
    delayWhileIdle: false
    timeToLive: 60 * 60 * 24 * 7 # 7days
    data:
      message: title
      detail: message
      icon: icon
  sender.send message, [push_id], 4, (err, result)->
    console.error err if err

module.exports = notifier
