fs = require("fs")
request = require("superagent")

Call = require("../models/call")

module.exports = (app, config, redis) ->
    contacts = require("../../lib/contacts")(config, redis)
    application_helpers = require("../helpers/application")(config)

    secretAction = application_helpers.secretAction
    
    app.post "/transcription", secretAction, (req, res) ->
        result = req.body.result

        Call
            .findOne()
            .where("session", result.identifier)
            .sort("created_at", -1)
            .run (err, call) ->
                call.transcription = result.transcription
                call.save()

                contacts.get_info call.contact, (name, type) ->
                    url = "#{config.rackspace.voicemail_url()}/#{call.voicemail}"

                    footer = if call.contact != name
                        """
                        #{name}
                        #{type}: #{call.contact}
                        #{url}
                        """
                    else
                       url

                    text = """
                        #{call.transcription}

                        --
                        #{footer}
                        """

                    mail_headers = 
                        from:    "#{name} <#{call.contact}@#{config.mailgun.domain()}>"
                        to:      config.full_email()
                        subject: "Voicemail from #{name}"
                        text:    text

                    request
                        .post("https://api.mailgun.net/v2/#{config.mailgun.domain()}/messages")
                        .auth("api", config.mailgun.api_key())
                        .type("form")
                        .send(mail_headers)
                        .end()

        res.send()

    app.post "/recording", secretAction, (req, res) ->
        if req.files
            file = req.files.filename
            filename = file.filename
            session = req.body.session

            request
                .get("https://auth.api.rackspacecloud.com/v1.0")
                .set("X-Auth-User", config.rackspace.user())
                .set("X-Auth-Key", config.rackspace.key())
                .end (res) ->
                    stream = fs.createReadStream(file.path)
                    req = request
                        .put(res.header["x-storage-url"] + "/voicemail/#{filename}")
                        .set("X-Auth-Token", res.header["x-auth-token"])
                    req.on "response", (res) ->
                        Call
                            .findOne()
                            .where("session", session)
                            .sort("created_at", -1)
                            .run (err, doc) ->
                                doc.voicemail = filename
                                doc.save()
                    stream.pipe req

        res.send()