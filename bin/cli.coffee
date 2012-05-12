#!/usr/bin/env coffee

optimist = require("optimist").usage("Usage: $0")

optimist.alias("p", "port")
optimist.default("p", 3000)
optimist.describe("p", "Runs Abbott on the specified port.")

optimist.alias("r", "redis-url")
optimist.default("r", "redis://localhost:6379")
optimist.describe("r", "Connects to Redis at the specified URL.")

optimist.alias("m", "mongo-url")
optimist.default("m", "mongodb://localhost:27017")
optimist.describe("m", "Connects to MongoDB at the specified URL.")

if optimist.argv.help
    optimist.showHelp()
else
    require("../config/application")(optimist.argv)