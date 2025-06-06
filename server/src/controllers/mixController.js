const Mix = require('../models/Mix');

// Получить все миксы
exports.getAllMixes = async (req, res) => {
    try {
        const mixes = await Mix.find();
        res.json(mixes);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Создать новый микс
exports.createMix = async (req, res) => {
    const mix = new Mix(req.body);
    try {
        const newMix = await mix.save();
        res.status(201).json(newMix);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// Обновить микс
exports.updateMix = async (req, res) => {
    console.log('PUT /mixes/:id called');
    console.log('Request body:', req.body);
    try {
        const mix = await Mix.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (!mix) {
            return res.status(404).json({ message: 'Микс не найден' });
        }
        res.json(mix);
    } catch (error) {
        console.error('Error updating mix:', error);
        res.status(400).json({ message: error.message });
    }
};

// Удалить микс
exports.deleteMix = async (req, res) => {
    try {
        const mix = await Mix.findByIdAndDelete(req.params.id);
        if (!mix) {
            return res.status(404).json({ message: 'Мисок не найден' });
        }
        res.json({ message: 'Мисок удален' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 