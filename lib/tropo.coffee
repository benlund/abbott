class Tropo
    constructor: ->
        @root = 
            tropo: []
    
    add: (action, parameters) ->
        obj = {}
        obj[action] = parameters || null
        @root.tropo.push obj
        
module.exports = Tropo