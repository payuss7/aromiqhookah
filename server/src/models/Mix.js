const mongoose = require('mongoose');

const mixSchema = new mongoose.Schema({
    _id: {
        type: String,
        required: true
    },
    profileId: {
        type: String,
        required: true,
        index: true // Добавляем индекс для быстрого поиска по profileId
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

module.exports = mongoose.model('Mix', mixSchema);