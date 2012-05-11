Tropo = require("../../lib/tropo")

module.exports = 
    tropoAction: (req, res, next) ->
        req.t = new Tropo
        req.result = req.body.result
        req.session = req.body.session

        next()

        res.contentType "application/json"
        res.send req.t.toJSON