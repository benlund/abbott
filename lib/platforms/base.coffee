class Base
    constructor: (argv) ->
        @argv = argv
    
    redis_url: ->
        @argv["redis-url"]
    
    mongo_url: ->
        @argv["mongo-url"]
    
    port: ->
        @argv.port
    
    name: ->
        process.env.ABBOTT_NAME
    
    email: ->
        process.env.ABBOTT_EMAIL
        
    full_email: ->
        "#{@name()} <#{@email()}>"        
        
    primary_number: ->
        process.env.ABBOTT_PRIMARY_NUMBER
        
    phones: ->
        process.env.ABBOTT_PHONES.split(",")
        
    ringback_tone: ->
        process.env.ABBOTT_RINGBACK_TONE
        
    secret: ->
        process.env.ABBOTT_SECRET
        
    mailgun:
        api_key: ->
            process.env.ABBOTT_MAILGUN_API_KEY
        domain: ->
            process.env.ABBOTT_MAILGUN_DOMAIN
            
    tropo:
        id: ->
            process.env.ABBOTT_TROPO_ID
        
        messaging_token: ->
            process.env.ABBOTT_TROPO_MESSAGING_TOKEN
            
    google:
        refresh_token: ->
            process.env.ABBOTT_GOOGLE_REFRESH_TOKEN
            
        client_id: ->
            process.env.ABBOTT_GOOGLE_CLIENT_ID
            
        client_secret: ->
            process.env.ABBOTT_GOOGLE_CLIENT_SECRET
            
    rackspace:
        voicemail_url: ->
            process.env.ABBOTT_CLOUDFILES_URL
            
        user: ->
            process.env.ABBOTT_RACKSPACE_USER
            
        key: ->
            process.env.ABBOTT_RACKSPACE_KEY

module.exports = Base