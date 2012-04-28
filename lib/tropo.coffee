class Tropo
    constructor: ->
        @root = 
            tropo: []
    
    add: (action, parameters) ->
        unless parameters
            parameters = null
        obj = {}
        obj[action] = parameters
        @root.tropo.push obj
        
module.exports = Tropo