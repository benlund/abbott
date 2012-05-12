request = require("superagent")
mail_helpers = require("../helpers/mail")

module.exports = (app, config, redis) ->
    app.post "/incoming", mail_helpers.mailgunAction, (req, res) ->
        if req.body.sender == process.env.ABBOTT_EMAIL
            message = req.body["stripped-text"]
            contact = req.body.recipient.split("@")[0]

            unless req.body.subject.match(/Voicemail/)
                redis.set contact, req.body["Message-Id"]

            body =
                to:     contact
                msg:    message
                token:  process.env.ABBOTT_TROPO_MESSAGING_TOKEN
                source: "email"

            request
                .post("https://api.tropo.com/1.0/sessions")
                .send(body)
                .set("Accept", "application/json")
                .end()

        res.send()