require("sugar")

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

        """\033[#{color}m#{(new Date).toUTCString()}:\033[m #{req.method} #{req.originalUrl} service=#{new Date - req._startTime}ms status=#{status} bytes=#{res._headers["content-length"]}"""

    app.use express.bodyParser()

    redis = require("redis-url").connect(config.redis_url())

    mongoose = require("mongoose")
    mongoose.connect(config.mongo_url())
    
    airbrake = require("airbrake").createClient(config.airbrake_api_key())
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