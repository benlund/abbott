Base = require("./base")

class DotCloud extends Base
    redis_url: ->
        process.env.DOTCLOUD_DATA_REDIS_URL
    
    mongo_url: ->
        process.env.DOTCLOUD_DATA_MONGODB_URL
    
    port: ->
        8080

module.exports = DotCloud