Base = require("./base")

class Heroku extends Base
    redis_url: ->
        console.log(@env)
        @env.REDISTOGO_URL

    mongo_url: ->
        @env.MONGOLAB_URI

    port: ->
        @env.PORT

module.exports = Heroku