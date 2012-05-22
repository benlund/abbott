module.exports = (argv) ->
    platform = argv.platform || process.env.npm_config_platform || process.env.PLATFORM
    klass = if platform
        require("./platforms/#{platform}")
    else
        require("./platforms/base")
    
    new klass(argv)