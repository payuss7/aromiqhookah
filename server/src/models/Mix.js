const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const mixSchema = new mongoose.Schema({
    _id: {
        type: String,
        default: uuidv4
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
        default: ''
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