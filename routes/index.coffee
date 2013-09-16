
exports.index = (twitter, db)->
  (req, res)->
    db (err, client, done)->
      return res.render "index", message: err.detail if err
      return res.render "index", accounts: null if not req.session.push_id?
      client.query 'SELECT * from users where push_id=$1',[req.session.push_id], (err, result)->
        done()
        return res.render "index", message: err.detail if err
        twitter.lookupUsers (q.id for q in result.rows), (a,b)->
          return res.render "index", accounts: b
