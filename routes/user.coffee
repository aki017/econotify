notifier = require "../notifier"

exports.registor = (twitter)->
  (req, res)->
    req.session.push_id = req.query.push_id
    return res.render "index", message: "push_id is null" unless req.query.push_id
    twitter.login("/user/registor", "/user/finish")(req, res)

exports.finish = (twitter, db)->
  (req, res)->
    twitter.gatekeeper() req, res, ()->
      req_cookie = twitter.cookie req
      res.clearCookie "twauth"
      twitter.options.access_token_key = req_cookie.access_token_key
      twitter.options.access_token_secret = req_cookie.access_token_secret

      twitter.verifyCredentials (err, data)->
        return console.log("Verification failed : " + err) if err
        id = data.id
        push_id = req.session.push_id
        token = twitter.options.access_token_key
        secret = twitter.options.access_token_secret
        regexp = data.screen_name

        db (err, client, done)->
          return console.error 'error fetching client from pool', err if err
          client.query 'INSERT INTO users(id, push_id, token, secret, regexp) VALUES ($1, $2, $3, $4, $5);', [id, push_id, token, secret, regexp], (err, result)->
            done()
            return res.render "index", message: err.detail if err
            notifier push_id, token, secret, regexp
            res.render "index", message: "finish"

exports.remove = (req, res)->
  res.render "confirm",
    title: "確認"
    message: "本当に削除しますか？"
    positive:
      label: "削除"
      url: "/user/confirm?id=#{req.query.id}"
    negative:
      label: "キャンセル"
      url: ""

exports.confirm = (db)->
  (req, res)->
    db (err, client, done)->
      return console.error 'error fetching client from pool', err if err
      push_id = req.session.push_id
      id = req.query.id
      client.query 'DELETE FROM users WHERE id=$1 AND push_id=$2', [id, push_id], (err, result)->
        done()
        console.log result
        return res.render "index", message: err.detail if err
        res.redirect "/index"
