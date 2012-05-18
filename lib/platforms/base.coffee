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
        
    mailgun_api_key: ->
        @env.ABBOTT_MAILGUN_API_KEY
    mailgun_domain: ->
        @env.ABBOTT_MAILGUN_DOMAIN
        
    tropo_id: ->
        @env.ABBOTT_TROPO_ID
    tropo_messaging_token: ->
        @env.ABBOTT_TROPO_MESSAGING_TOKEN
            
    google_refresh_token: ->
        @env.ABBOTT_GOOGLE_REFRESH_TOKEN
    google_client_id: ->
        @env.ABBOTT_GOOGLE_CLIENT_ID
    google_client_secret: ->
        @env.ABBOTT_GOOGLE_CLIENT_SECRET
            
    rackspace_voicemail_url: ->
        @env.ABBOTT_CLOUDFILES_URL
    rackspace_user: ->
        @env.ABBOTT_RACKSPACE_USER
    rackspace_key: ->
        @env.ABBOTT_RACKSPACE_KEY
        
    airbrake_api_key: ->
        @env.ABBOTT_AIRBRAKE_API_KEY

module.exports = Base