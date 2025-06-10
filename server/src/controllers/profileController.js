const Profile = require('../models/Profile');

// Получить все профили
exports.getProfiles = async (req, res) => {
    try {
        const profiles = await Profile.find();
        res.json(profiles);
    } catch (error) {
        console.error('Ошибка при получении профилей:', error);
        res.status(500).json({ message: 'Ошибка сервера при получении профилей' });
    }
};

// Создать новый профиль
exports.createProfile = async (req, res) => {
    console.log('profileController: Получен запрос на создание профиля');
    try {
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ message: 'Имя профиля обязательно' });
        }

        const profile = new Profile({
            name,
            isActive: false
        });

        await profile.save();
        res.status(201).json(profile);
    } catch (error) {
        console.error('Ошибка при создании профиля:', error);
        res.status(500).json({ message: 'Ошибка сервера при создании профиля' });
    }
};

// Обновить профиль
exports.updateProfile = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, isActive } = req.body;

        const profile = await Profile.findById(id);
        if (!profile) {
            return res.status(404).json({ message: 'Профиль не найден' });
        }

        if (name) profile.name = name;
        if (typeof isActive === 'boolean') profile.isActive = isActive;

        await profile.save();
        res.json(profile);
    } catch (error) {
        console.error('Ошибка при обновлении профиля:', error);
        res.status(500).json({ message: 'Ошибка сервера при обновлении профиля' });
    }
};

// Удалить профиль
exports.deleteProfile = async (req, res) => {
    try {
        const { id } = req.params;
        const profile = await Profile.findById(id);
        
        if (!profile) {
            return res.status(404).json({ message: 'Профиль не найден' });
        }

        await Profile.findByIdAndDelete(id);
        res.json({ message: 'Профиль успешно удален' });
    } catch (error) {
        console.error('Ошибка при удалении профиля:', error);
        res.status(500).json({ message: 'Ошибка сервера при удалении профиля' });
    }
}; 