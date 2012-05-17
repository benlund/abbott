request = require("superagent")

module.exports = (app, config, redis) ->
    mail_helpers = require("../helpers/mail")(config)
    
    app.post "/incoming", mail_helpers.mailgunAction, (req, res) ->
        if req.body.sender == config.email()
            message = req.body["stripped-text"]
            contact = req.body.recipient.split("@")[0]

            unless req.body.subject.match(/Voicemail/)
                redis.set contact, req.body["Message-Id"]

            body =
                to:     contact
                msg:    message
                token:  config.tropo_messaging_token()
                source: "email"

            request
                .post("https://api.tropo.com/1.0/sessions")
                .send(body)
                .set("Accept", "application/json")
                .end()

        res.send()