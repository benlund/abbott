class Base
    constructor: (argv, env = process.env) ->
        @argv = argv
        @env = env
    
    redis_url: ->
        @argv["redis-url"]
    
    mongo_url: ->
        @argv["mongo-url"]
    
    port: ->
        @argv.port
    
    name: ->
        @env.ABBOTT_NAME
    
    email: ->
        @env.ABBOTT_EMAIL
        
    full_email: ->
        "#{@name()} <#{@email()}>"        
        
    primary_number: ->
        @env.ABBOTT_PRIMARY_NUMBER
        
    phones: ->
        @env.ABBOTT_PHONES.split(",")
        
    ringback_tone: ->
        @env.ABBOTT_RINGBACK_TONE
        
    secret: ->
        @env.ABBOTT_SECRET
        
    mailgun:
        api_key: ->
            @env.ABBOTT_MAILGUN_API_KEY
        domain: ->
            @env.ABBOTT_MAILGUN_DOMAIN
            
    tropo:
        id: ->
            @env.ABBOTT_TROPO_ID
        
        messaging_token: ->
            @env.ABBOTT_TROPO_MESSAGING_TOKEN
            
    google:
        refresh_token: ->
            console.log(this)
            console.dir(this)
            @env.ABBOTT_GOOGLE_REFRESH_TOKEN
            
        client_id: ->
            @env.ABBOTT_GOOGLE_CLIENT_ID
            
        client_secret: ->
            @env.ABBOTT_GOOGLE_CLIENT_SECRET
            
    rackspace:
        voicemail_url: ->
            @env.ABBOTT_CLOUDFILES_URL
            
        user: ->
            @env.ABBOTT_RACKSPACE_USER
            
        key: ->
            @env.ABBOTT_RACKSPACE_KEY

module.exports = Base