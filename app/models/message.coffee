mongoose = require("mongoose")

MessageSchema = new mongoose.Schema
    text:       String
    contact:    String
    source:     String
    outgoing:   Boolean
    created_at:
        type: Date
        default: Date.now
    
module.exports = mongoose.model("Message", MessageSchema)