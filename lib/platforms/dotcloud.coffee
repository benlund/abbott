fs = require("fs")
Base = require("./base")

class DotCloud extends Base
    constructor: (argv) ->
        env = JSON.parse(fs.readFileSync("/home/dotcloud/environment.json", "utf-8"))
        super(argv, env)
    
    redis_url: ->
        @env.DOTCLOUD_CACHE_REDIS_URL
    
    mongo_url: ->
        @env.DOTCLOUD_DATA_MONGODB_URL
    
    port: ->
        8080

module.exports = DotCloud