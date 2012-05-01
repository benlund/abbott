qs = require("querystring")

module.exports = (app, redis) ->
    app.get "/authorize", (req, res) ->
        unless process.env.ABBOTT_GOOGLE_REFRESH_TOKEN
            oauth_params = 
                scope:           "https://www.google.com/m8/feeds"
                client_id:       process.env.ABBOTT_GOOGLE_CLIENT_ID
                access_type:     "offline"
                redirect_uri:    "https://#{req.header("Host")}/oauth2callback"
                response_type:   "code"
                approval_prompt: "force"
        
            query = qs.stringify oauth_params
            res.redirect "https://accounts.google.com/o/oauth2/auth?#{query}"
        else
            res.send("This server is already associated with a Google Account")
            
    app.get "/oauth2callback", (req, res) ->
        unless process.env.ABBOTT_GOOGLE_REFRESH_TOKEN
            data = 
                code:          req.query.code
                client_id:     process.env.ABBOTT_GOOGLE_CLIENT_ID
                grant_type:    "authorization_code"
                redirect_uri:  "https://#{req.header("Host")}/oauth2callback"
                client_secret: process.env.ABBOTT_GOOGLE_CLIENT_SECRET

            request
                .post("https://accounts.google.com/o/oauth2/token")
                .type("form")
                .send(data)
                .end (res) ->
                    redis.setex "access_token", res.body.expires_in, res.body.access_token

            res.send(res.body.refresh_token)
        else
            res.send("This server is already associated with a Google Account")