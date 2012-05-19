fs = require("fs")
url = require("url")
Base = require("./base")

class DotCloud extends Base
    constructor: (argv) ->
        env = JSON.parse(fs.readFileSync("/home/dotcloud/environment.json", "utf-8"))
        super(argv, env)

    redis_url: ->
        @env.DOTCLOUD_CACHE_REDIS_URL

    mongo_url: ->
        mongo = url.parse(@env.DOTCLOUD_DATA_MONGODB_URL)
        mongo.pathname = "/abbott"
        url.format(mongo)

    port: ->
        @env.PORT_WWW || 8080

module.exports = DotCloud