require("sugar")

url = require("url")

module.exports = (environment) ->
    config = require("../lib/config")(environment)

    express = require("express")
    app = express.createServer()
    app.use express.logger (tokens, req, res) ->
        status = res.statusCode
        
        color = if status >= 500
            31
        else if status >= 400
            33
        else if status >= 300
            36
        else
            32
            
        parts = url.parse(req.originalUrl, true)
        delete parts.query.secret
        path = url.format
            query: parts.query
            pathname: parts.pathname
            
        now = (new Date).toUTCString()
        response_time = new Date - req._startTime
        bytes = res._headers["content-length"] || 0

        """\033[#{color}m#{now}:\033[m #{req.method} #{path} service=#{response_time}ms status=#{status} bytes=#{bytes}"""

    app.use express.bodyParser()

    redis = require("redis-url").connect(config.redis_url())

    mongoose = require("mongoose")
    mongoose.connect(config.mongo_url())
    
    if airbrake_api_key = config.airbrake_api_key()
        airbrake = require("airbrake").createClient(airbrake_api_key)
        airbrake.handleExceptions()
        app.error (err, req, res, next) ->
            err.params = Object.merge(Object.merge(req.params, req.query), req.body)
            airbrake.notify(err)
            res.send(500)

    require("../app/controllers/main")(app, config, redis)
    require("../app/controllers/mail")(app, config, redis)
    require("../app/controllers/oauth")(app, config, redis)
    require("../app/controllers/voicemail")(app, config, redis)

    app.listen(config.port())