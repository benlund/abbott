url = require("url")
xml2js = require("xml2js")
request = require("superagent")

module.exports = (redis) ->
    get_contacts = (access_token, callback) ->
        redis.get "contacts:etag", (err, value) ->
            req = request
                .get("https://www.google.com/m8/feeds/contacts/default/full?max-results=10000")
                .set("GData-Version", "3.0")
                .set("Authorization", "Bearer #{access_token}")
    
            if value
                req.set("If-None-Match", value)
    
            req.end (res) ->
                if res.status == 304
                    redis.get "contacts", (err, value) ->
                        callback(value)
                else
                    redis.mset "contacts", res.text, "contacts:etag", res.header["etag"]
                    callback(res.text)        
    
    get_access_token = (callback) ->
        redis.get "access_token", (err, value) ->
            if value
                callback(value)
            else
                data = 
                    client_id: process.env.ABBOTT_GOOGLE_CLIENT_ID
                    client_secret: process.env.ABBOTT_GOOGLE_CLIENT_SECRET
                    grant_type: "refresh_token"
                    refresh_token: process.env.ABBOTT_GOOGLE_REFRESH_TOKEN
                
                request
                    .post("https://accounts.google.com/o/oauth2/token")
                    .type("form")
                    .send(data)
                    .end (res) ->
                        redis.setex "access_token", res.body.expires_in, res.body.access_token
                        callback(res.body.access_token)
    
    get_info: (contact, callback) ->
        get_access_token (token) ->
            get_contacts token, (contacts) ->
                parser = new xml2js.Parser
                    explicitArray: true
                parser.parseString contacts, (err, result) ->
                    entries = result["entry"].filter (entry) ->
                        entry["gd:phoneNumber"] && entry["gd:phoneNumber"].has (phoneNumber) ->
                            "+#{phoneNumber["#"].replace(/\D/g, "")}" == contact
    
                    if entries.length > 0
                        entry = entries[0]
                        name = entry.title[0]
                        phone = entry["gd:phoneNumber"].find (value) ->
                            "+#{value["#"].replace(/\D/g, "")}" == contact
    
                        type = phone["@"]["label"] || url.parse(phone["@"]["rel"]).fragment.titleize()
                        callback(name, type)
                    else
                        callback(contact)