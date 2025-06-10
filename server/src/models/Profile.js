const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    isActive: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Profile', profileSchema);