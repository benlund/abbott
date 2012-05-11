class Tropo
    constructor: ->
        @root = 
            tropo: []
    
    add: (action, parameters) ->
        obj = {}
        obj[action] = parameters || null
        @root.tropo.push obj
        
    toJSON: ->
        JSON.stringify(@root)
        
module.exports = Tropo