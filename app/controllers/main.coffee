request = require("superagent")

Call = require("../models/call")
Message = require("../models/message")

module.exports = (app, config, redis) ->
    contacts = require("../../lib/contacts")(config, redis)
    
    main_helpers = require("../helpers/main")(config)
    application_helpers = require("../helpers/application")(config)

    tropoAction = main_helpers.tropoAction
    secretAction = application_helpers.secretAction
    
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
                        from:    "#{name} <#{message.contact}@#{config.mailgun.domain()}>"
                        to:      config.full_email()
                        subject: "SMS from #{name}"
                        text:    message.text
    
                    if value
                        mail_headers["h:In-Reply-To"] = value
    
                    request
                        .post("https://api.mailgun.net/v2/#{config.mailgun.domain()}/messages")
                        .auth("api", config.mailgun.api_key())
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
                from:    config.primary_number()
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
                to:   config.phones()
                from: config.primary_number()

            req.t.add "say"
                value: "Transfering your call"
                voice: "kate"

            req.t.add "transfer"
                to:         contact
                from:       config.primary_number()
                timeout:    60
                ringRepeat: 20
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{config.tropo.id()}/www/audio/#{config.ringback_tone()}"

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
                from:       config.primary_number()
                timeout:    30
                ringRepeat: 10
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{config.tropo.id()}/www/audio/#{config.ringback_tone()}"

        else
            contact = req.session.from.name
    
            call = new Call
                source:   "tropo"
                session:  req.session.id
                contact:  contact
                outgoing: false
            call.save()
    
            req.t.add "transfer"
                to:         config.phones()
                from:       contact
                timeout:    27
                ringRepeat: 9
                on:
                    event: "ring"
                    say:
                        value: "http://hosting.tropo.com/#{config.tropo.id()}/www/audio/#{config.ringback_tone()}"

            req.t.add "on"
                event: "incomplete"
                next: "/voicemail?secret=#{config.secret()}"
    
    app.post "/voicemail", secretAction, tropoAction, (req, res) ->
        session = req.result.sessionId

        req.t.add "record"
            beep:  true
            url:   "https://#{req.header("Host")}/recording?session=#{session}&secret=#{config.secret()}"
            voice: "kate"
            say:
                value: "Please leave a message after the tone"
            transcription:
                id:  session
                url: "https://#{req.header("Host")}/transcription?secret=#{config.secret()}"

        req.t.add "hangup"