const Mix = require('../models/Mix');

// Получить все миксы для профиля
exports.getMixes = async (req, res) => {
    try {
        const { profileId } = req.query;
        if (!profileId) {
            return res.status(400).json({ message: 'ID профиля обязателен' });
        }

        const mixes = await Mix.find({ profileId });
        res.json(mixes);
    } catch (error) {
        console.error('Ошибка при получении миксов:', error);
        res.status(500).json({ message: 'Ошибка сервера при получении миксов' });
    }
};

// Создать новый микс
exports.createMix = async (req, res) => {
    try {
        const { profileId } = req.body;
        if (!profileId) {
            return res.status(400).json({ message: 'ID профиля обязателен' });
        }

        const mix = new Mix({
            ...req.body,
            _id: req.body.id // Используем id из запроса как _id
        });

        await mix.save();
        res.status(201).json(mix);
    } catch (error) {
        console.error('Ошибка при создании микса:', error);
        res.status(500).json({ message: 'Ошибка сервера при создании микса' });
    }
};

// Обновить микс
exports.updateMix = async (req, res) => {
    try {
        const { id } = req.params;
        const { profileId } = req.body;

        if (!profileId) {
            return res.status(400).json({ message: 'ID профиля обязателен' });
        }

        const mix = await Mix.findOne({ _id: id, profileId });
        if (!mix) {
            return res.status(404).json({ message: 'Микс не найден' });
        }

        Object.assign(mix, req.body);
        await mix.save();
        res.json(mix);
    } catch (error) {
        console.error('Ошибка при обновлении микса:', error);
        res.status(500).json({ message: 'Ошибка сервера при обновлении микса' });
    }
};

// Удалить микс
exports.deleteMix = async (req, res) => {
    try {
        const { id } = req.params;
        const { profileId } = req.query;

        if (!profileId) {
            return res.status(400).json({ message: 'ID профиля обязателен' });
        }

        const mix = await Mix.findOne({ _id: id, profileId });
        if (!mix) {
            return res.status(404).json({ message: 'Микс не найден' });
        }

        await Mix.findByIdAndDelete(id);
        res.json({ message: 'Микс успешно удален' });
    } catch (error) {
        console.error('Ошибка при удалении микса:', error);
        res.status(500).json({ message: 'Ошибка сервера при удалении микса' });
    }
}; 