const mixSchema = new mongoose.Schema({
    _id: {
        type: String,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    composition: {
        type: String,
        required: true
    },
    strength: {
        type: Number,
        required: true,
        min: 0,
        max: 10
    },
    notes: {
        type: String,
        default: ''
    },
    tags: [{
        type: String
    }],
    guestTags: [{
        type: String
    }],
    isInDevelopment: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});