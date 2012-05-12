module.exports = (argv) ->
    klass = if argv.platform
        require("./platforms/#{argv.platform}")
    else
        require("./platforms/base")
    
    new klass(argv)