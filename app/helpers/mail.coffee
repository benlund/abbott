crypto = require("crypto")

module.exports = 
    mailgunAction: (req, res, next) ->
        hmac = crypto.createHmac "sha256", process.env.ABBOTT_MAILGUN_API_KEY
        hmac.update(req.body.timestamp + req.body.token)
        if hmac.digest("hex") == req.body.signature
            next()
        else
            next(new Error("Invalid signature"))