require("sugar")

module.exports = (environment) ->
    config = require("../lib/config")(environment)

    express = require("express")
    app = express.createServer()
    app.use express.bodyParser()

    redis = require("redis-url").connect(config.redis_url())

    mongoose = require("mongoose")
    mongoose.connect(config.mongo_url())

    require("../app/controllers/main")(app, config, redis)
    require("../app/controllers/mail")(app, config, redis)
    require("../app/controllers/oauth")(app, config, redis)
    require("../app/controllers/voicemail")(app, config, redis)

    app.listen(config.port())