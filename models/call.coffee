mongoose = require("mongoose")

CallSchema = new mongoose.Schema
    contact:       String
    session:       String
    outgoing:      Boolean
    voicemail:     String
    transcription: String
    source:        String
    created_at:
        type: Date
        default: Date.now
    
module.exports = mongoose.model("Call", CallSchema)
