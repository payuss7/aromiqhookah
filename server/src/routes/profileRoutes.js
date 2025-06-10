const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');

// Получить все профили
router.get('/', profileController.getProfiles);

// Создать новый профиль
router.post('/', profileController.createProfile);

// Обновить профиль
router.put('/:id', profileController.updateProfile);

// Удалить профиль
router.delete('/:id', profileController.deleteProfile);

module.exports = router; 