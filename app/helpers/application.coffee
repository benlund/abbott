module.exports = 
    secretAction: (req, res, next) ->
        if req.query.secret == process.env.ABBOTT_SECRET
            next()
        else
            next(new Error("Invalid secret"))