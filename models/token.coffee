mongoose = require("mongoose")

TokenSchema = new mongoose.Schema
    refresh_token: String
    
module.exports = mongoose.model("Token", TokenSchema)