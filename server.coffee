# Standard
fs = require("fs")
crypto = require("crypto")
qs = require("querystring")

# Express
express = require("express")
app = express.createServer()
app.use express.bodyParser()

# Mongoose
mongoose = require("mongoose")
mongoose.connect(process.env.MONGOLAB_URI)
Call = require("./models/call")
Token = require("./models/token")
Message = require("./models/message")

# Tropo
Tropo = require("./lib/tropo")

# SuperAgent
request = require("superagent")

# Redis
redis = require("redis-url").connect(process.env.REDISTOGO_URL)

# Sugar
require("sugar")

# xml2js
xml2js = require("xml2js")

tropoAction = (req, res, next) ->
    req.t = new Tropo
    req.result = req.body.result
    req.session = req.body.session
    
    next()
    
    res.contentType "application/json"
    res.send(JSON.stringify(req.t.root))
    
mailgunAction = (req, res, next) ->
    hmac = crypto.createHmac "sha256", process.env.ABBOTT_MAILGUN_API_KEY
    hmac.update(req.body.timestamp + req.body.token)
    if hmac.digest("hex") == req.body.signature
        next()    
    else
        next(new Error("Invalid signature"))
        
secretAction = (req, res, next) ->
    if req.query.secret == process.env.ABBOTT_SECRET
        next()
    else
        next(new Error("Invalid secret"))
        
get_contacts = (access_token, callback) ->
    redis.get "contacts:etag", (err, value) ->
        req = request
            .get("https://www.google.com/m8/feeds/contacts/default/full?max-results=10000")
            .set("GData-Version", "3.0")
            .set("Authorization", "Bearer #{access_token}")

        if value
            req.set("If-None-Match", value)

        req.end (res) ->
            if res.status == 304
                redis.get "contacts", (err, value) ->
                    callback(value)
            else
                redis.set "contacts", res.text
                redis.set "contacts:etag", res.header["etag"]
                callback(res.text)        

get_access_token = (callback) ->
    redis.get "access_token", (err, value) ->
        if value
            callback(value)
        else
            Token.findOne {}, (err, doc) ->
                data = 
                    client_id: process.env.ABBOTT_GOOGLE_CLIENT_ID
                    client_secret: process.env.ABBOTT_GOOGLE_CLIENT_SECRET
                    grant_type: "refresh_token"
                    refresh_token: doc.refresh_token

                request
                    .post("https://accounts.google.com/o/oauth2/token")
                    .type("form")
                    .send(data)
                    .end (res) ->
                        callback(res.body.access_token)
                        redis.set "access_token", res.body.access_token, (err, value) ->
                            redis.expire "access_token", res.body.expires_in
                            
get_contact_info = (contact, callback) ->
    get_access_token (token) ->
        get_contacts token, (contacts) ->
            parser = new xml2js.Parser
                explicitArray: true
            parser.parseString contacts, (err, result) ->
                entries = result["entry"].filter (entry) ->
                    entry["gd:phoneNumber"] && entry["gd:phoneNumber"].has (phoneNumber) ->
                        "+#{phoneNumber["#"].replace(/\D/g, "")}" == contact
                 
                if entries.length > 0
                    entry = entries[0]
                    name = entry.title[0]
                    phone = entry["gd:phoneNumber"].find (value) ->
                        "+#{value["#"].replace(/\D/g, "")}" == contact
                        
                    type = phone["@"]["label"] || url.parse(phone["@"]["rel"]).fragment.titleize()
                    callback(name, type)
                else
                    callback(contact)

app.post "/text", secretAction, tropoAction, (req, res) ->
    initialText = req.session.initialText
    
    if initialText
        contact = "+#{req.session.from.id}"
        
        message = new Message
            text:     initialText
            contact:  contact
            outgoing: false
            source:   "tropo"
        message.save()
        
        redis.get message.contact, (err, value) ->
            get_contact_info message.contact, (name, type) ->
                mail_headers =
                    from: "#{name} <#{message.contact}@#{process.env.ABBOTT_MAILGUN_DOMAIN}>"
                    to: "#{process.env.ABBOTT_NAME} <#{process.env.ABBOTT_EMAIL}>"
                    subject: "SMS from #{name}"
                    text: message.text
                    
                if value
                    mail_headers["h:In-Reply-To"] = value
                
                request
                    .post("https://api:#{process.env.ABBOTT_MAILGUN_API_KEY}@api.mailgun.net/v2/abbott.mailgun.org/messages")
                    .type("form")
                    .send(mail_headers)
                    .end()
            
    else
        to = req.session.parameters.to
        text = req.session.parameters.msg
        
        message = new Message
            text:     text
            contact:  to
            outgoing: true
            source:   req.session.parameters.source || "unknown"
        message.save()
        
        req.t.add "message"
            to: to
            channel: "TEXT"
            from: process.env.ABBOTT_PRIMARY_NUMBER
            say: 
                value: text
                
    req.t.add "hangup"
    
app.post "/voice", secretAction, tropoAction, (req, res) ->
    if req.session.parameters
        contact = req.session.parameters.contact
        source = req.session.parameters.source || "unknown"
        
        call = new Call
            session:  req.session.id
            contact:  contact
            outgoing: true
            source:   source
        call.save()        
        
        req.t.add "call"
            to: process.env.ABBOTT_PHONES.split(",")
            from: process.env.ABBOTT_PRIMARY_NUMBER
        req.t.add "say"
            value: "Transfering your call"
            voice: "kate"
        req.t.add "transfer"
            to: contact
            from: process.env.ABBOTT_PRIMARY_NUMBER
            on:
                event: "ring"
                say:
                    value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"
            ringRepeat: 20
            timeout: 60
    else if req.session.headers["x-voxeo-to"].match(/<sip:999/)
        contact = req.session.headers["x-sbc-request-uri"].split(";")[1]
        
        call = new Call
            session:  req.session.id
            contact:  contact
            outgoing: true
            source:   "sip"
        call.save()
        
        req.t.add "say"
            value: "Transfering your call"
            voice: "kate"
        req.t.add "transfer"
            to: contact
            on:
                event: "ring"
                say:
                    value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"
            ringRepeat: 10
    else
        contact = req.session.from.name
        
        call = new Call
            session:  req.session.id
            contact:  contact
            outgoing: false
            source:   "tropo"
        call.save()
        
        req.t.add "transfer"
            to: process.env.ABBOTT_PHONES.split(",")
            ringRepeat: 9
            on:
                event: "ring"
                say:
                    value: "http://hosting.tropo.com/#{process.env.ABBOTT_TROPO_ID}/www/audio/#{process.env.ABBOTT_RINGBACK_TONE}"
            from: contact
            timeout: 27
        req.t.add "on"
            event: "incomplete"
            next: "/voicemail?secret=#{process.env.ABBOTT_SECRET}"
            
app.post "/voicemail", secretAction, tropoAction, (req, res) ->
    session = req.result.sessionId
    req.t.add "record"
        say:
            value: "Please leave a message after the tone"
        transcription:
            id: session
            url: "https://#{req.header("Host")}/transcription?secret=#{process.env.ABBOTT_SECRET}"
        beep: true
        url: "https://#{req.header("Host")}/recording?session=#{session}&secret=#{process.env.ABBOTT_SECRET}"
        voice: "kate"
    req.t.add "hangup"
    
app.post "/transcription", secretAction, (req, res) ->
    result = req.body.result
    
    Call
        .findOne()
        .where("session", result.identifier)
        .sort("created_at", -1)
        .run (err, call) ->
            call.transcription = result.transcription
            call.save()
            
            get_contact_info call.contact, (name, type) ->
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
                    from: "#{name} <#{call.contact}@#{process.env.ABBOTT_MAILGUN_DOMAIN}>"
                    to: "#{process.env.ABBOTT_NAME} <#{process.env.ABBOTT_EMAIL}>"
                    subject: "Voicemail from #{name}"
                    text: text
                
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
    
app.post "/incoming", mailgunAction, (req, res) ->
    if req.body.sender == process.env.ABBOTT_EMAIL
        message = req.body["stripped-text"]
        contact = req.body.recipient.split("@")[0]
        
        unless req.body.subject.match(/Voicemail/)
            redis.set contact, req.body["Message-Id"]
            
        body =
            token: process.env.ABBOTT_TROPO_MESSAGING_TOKEN
            to: contact
            msg: message
            source: "email"
            
        request
            .post("https://api.tropo.com/1.0/sessions")
            .send(body)
            .set("Accept", "application/json")
            .end()
        
    res.send()
    
app.get "/authorize", (req, res) ->
    Token.count {}, (err, count) ->
        if count == 0
            oauth_params = 
                response_type: "code"
                client_id: process.env.ABBOTT_GOOGLE_CLIENT_ID
                redirect_uri: "https://#{req.header("Host")}/oauth2callback"
                access_type: "offline"
                approval_prompt: "force"
                scope: "https://www.google.com/m8/feeds"

            query = qs.stringify oauth_params
            res.redirect "https://accounts.google.com/o/oauth2/auth?#{query}"
        else
            res.send("This server is already associated with a Google Account")
    
app.get "/oauth2callback", (req, res) ->
    Token.count {}, (err, count) ->
        if count == 0
            data = 
                code: req.query.code
                client_id: process.env.ABBOTT_GOOGLE_CLIENT_ID
                client_secret: process.env.ABBOTT_GOOGLE_CLIENT_SECRET
                redirect_uri: "https://#{req.header("Host")}/oauth2callback"
                grant_type: "authorization_code"

            request
                .post("https://accounts.google.com/o/oauth2/token")
                .type("form")
                .send(data)
                .end (res) ->
                    redis.set "access_token", res.body.access_token, (err, value) ->
                        redis.expire "access_token", res.body.expires_in
                    
                    token = new Token
                        refresh_token: res.body.refresh_token
                        
                    token.save()
            res.send("Success!")
        else
            res.send("This server is already associated with a Google Account")

        

app.listen(process.env.PORT || 3000)