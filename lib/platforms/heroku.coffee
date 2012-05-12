Base = require("./base")

class Heroku extends Base
    redis_url: ->
        process.env.REDISTOGO_URL

    mongo_url: ->
        process.env.MONGOLAB_URI

    port: ->
        process.env.PORT

module.exports = Heroku