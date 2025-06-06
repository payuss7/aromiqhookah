const Mix = require('../models/Mix');

// Получить все миксы
exports.getAllMixes = async (req, res) => {
    try {
        const mixes = await Mix.find();
        // Преобразуем _id в id для каждого микса
        const mixesWithId = mixes.map(mix => {
            const obj = mix.toObject();
            obj.id = obj._id;
            delete obj._id;
            return obj;
        });
        res.json(mixesWithId);
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

    // Если в теле запроса есть id, но нет _id — добавляем _id для совместимости с Mongoose
    if (!req.body._id && req.body.id) {
        req.body._id = req.body.id;
    }

    try {
        const mix = await Mix.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, upsert: true } // upsert: true — создаст документ, если не найден
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