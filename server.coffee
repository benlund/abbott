#!/usr/bin/env coffee

require("sugar")

express = require("express")
app = express.createServer()
app.use express.bodyParser()

redis = require("redis-url").connect(process.env.REDISTOGO_URL)

mongoose = require("mongoose")
mongoose.connect(process.env.MONGOLAB_URI)

require("./app/controllers/main")(app, redis)
require("./app/controllers/mail")(app, redis)
require("./app/controllers/oauth")(app, redis)
require("./app/controllers/voicemail")(app, redis)

app.listen(process.env.PORT || 3000)