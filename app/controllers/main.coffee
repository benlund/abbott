request = require("superagent")

Call = require("../models/call")
Message = require("../models/message")

main_helpers = require("../helpers/main")
application_helpers = require("../helpers/application")

tropoAction = main_helpers.tropoAction
secretAction = application_helpers.secretAction

module.exports = (app, config, redis) ->
    contacts = require("../../lib/contacts")(redis)
    
    app.post "/text", secretAction, tropoAction, (req, res) ->
        initialText = req.session.initialText

        if initialText
            contact = "+#{req.session.from.id}"

            message = new Message
                text:     initialText
                source:   "tropo"
                contact:  contact
                outgoing: false
            message.save()
    
            redis.get message.contact, (err, value) ->
                contacts.get_info message.contact, (name, type) ->
                    mail_headers =
                        from:    "#{name} <#{message.contact}@#{process.env.ABBOTT_MAILGUN_DOMAIN}>"
                        to:      "#{process.env.ABBOTT_NAME} <#{process.env.ABBOTT_EMAIL}>"
                        subject: "SMS from #{name}"
                        text:    message.text
    
                    if value
                        mail_headers["h:In-Reply-To"] = value
    
                    request
                        .post("https://api.mailgun.net/v2/#{process.env.ABBOTT_MAILGUN_DOMAIN}/messages")
                        .auth("api", process.env.ABBOTT_MAILGUN_API_KEY)
                        .type("form")
                        .send(mail_headers)
                        .end()
    
        else
            to = req.session.parameters.to
            text = req.session.parameters.msg
    
            message = new Message
                text:     text
                source:   req.session.parameters.source || "unknown"
                contact:  to
                outgoing: true
            message.save()
    
            req.t.add "message"
                to:      to
                from:    process.env.ABBOTT_PRIMARY_NUMBER
                channel: "TEXT"
                say:
                    value: text
    
        req.t.add "hangup"
    
    app.post "/voice", secretAction, tropoAction, (req, res) ->
        if req.session.parameters
            contact = req.session.parameters.contact
            source = req.session.parameters.source || "unknown"
    
            call = new Call
                source:   source
                session:  req.session.id
                contact:  contact
                outgoing: true
            call.save()        
    
            req.t.add "call"
                to:   process.env.ABBOTT_PHONES.split(",")
                from: process.env.ABBOTT_PRIMARY_NUMBER

            req.t.add "say"
                value: "Transfering your call"
                voice: "kate"

            req.t.add "transfer"
                to:         contact
                from:       process.env.ABBOTT_PRIMARY_NUMBER
                timeout:    60
                ringRepeat: 20
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"

        else if req.session.headers["x-voxeo-to"].match(/<sip:999/)
            contact = req.session.headers["x-sbc-request-uri"].split(";")[1]
    
            call = new Call
                source:   "sip"
                session:  req.session.id
                contact:  contact
                outgoing: true
            call.save()
    
            req.t.add "say"
                value: "Transfering your call"
                voice: "kate"

            req.t.add "transfer"
                to:         contact
                from:       process.env.ABBOTT_PRIMARY_NUMBER
                timeout:    30
                ringRepeat: 10
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"

        else
            contact = req.session.from.name
    
            call = new Call
                source:   "tropo"
                session:  req.session.id
                contact:  contact
                outgoing: false
            call.save()
    
            req.t.add "transfer"
                to:         process.env.ABBOTT_PHONES.split(",")
                from:       contact
                timeout:    27
                ringRepeat: 9
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"

            req.t.add "on"
                event: "incomplete"
                next: "/voicemail?secret=#{process.env.ABBOTT_SECRET}"
    
    app.post "/voicemail", secretAction, tropoAction, (req, res) ->
        session = req.result.sessionId

        req.t.add "record"
            beep:  true
            url:   "https://#{req.header("Host")}/recording?session=#{session}&secret=#{process.env.ABBOTT_SECRET}"
            voice: "kate"
            say:
                value: "Please leave a message after the tone"
            transcription:
                id:  session
                url: "https://#{req.header("Host")}/transcription?secret=#{process.env.ABBOTT_SECRET}"

        req.t.add "hangup"