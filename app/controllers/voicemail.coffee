fs = require("fs")
request = require("superagent")
Call = require("../models/call")
application_helpers = require("../helpers/application")

secretAction = application_helpers.secretAction

module.exports = (app, redis) ->
    contacts = require("../../lib/contacts")(redis)
    
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
                    url = "#{process.env.ABBOTT_CLOUDFILES_URL}/#{call.voicemail}"

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
                        from:    "#{name} <#{call.contact}@#{process.env.ABBOTT_MAILGUN_DOMAIN}>"
                        to:      "#{process.env.ABBOTT_NAME} <#{process.env.ABBOTT_EMAIL}>"
                        subject: "Voicemail from #{name}"
                        text:    text

                    request
                        .post("https://api:#{process.env.ABBOTT_MAILGUN_API_KEY}@api.mailgun.net/v2/abbott.mailgun.org/messages")
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
                .set("X-Auth-User", process.env.ABBOTT_RACKSPACE_USER)
                .set("X-Auth-Key", process.env.ABBOTT_RACKSPACE_KEY)
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