class Base
    constructor: (argv) ->
        @argv = argv
    
    redis_url: ->
        @argv["redis-url"]
    
    mongo_url: ->
        @argv["mongo-url"]
    
    port: ->
        @argv.port
        
module.exports = Base