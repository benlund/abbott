crypto = require("crypto")

module.exports = (config) ->
    mailgunAction: (req, res, next) ->
        hmac = crypto.createHmac "sha256", config.mailgun.api_key()
        hmac.update(req.body.timestamp + req.body.token)
        if hmac.digest("hex") == req.body.signature
            next()
        else
            next(new Error("Invalid signature"))