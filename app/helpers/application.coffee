module.exports = (config) ->
    secretAction: (req, res, next) ->
        if req.query.secret == config.secret()
            next()
        else
            next(new Error("Invalid secret"))