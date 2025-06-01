const express = require('express');
const router = express.Router();
const mixController = require('../controllers/mixController');

// GET /mixes - получить все миксы
router.get('/', mixController.getAllMixes);

// POST /mixes - создать новый микс
router.post('/', mixController.createMix);

// PUT /mixes/:id - обновить микс
router.put('/:id', mixController.updateMix);

// DELETE /mixes/:id - удалить микс
router.delete('/:id', mixController.deleteMix);

module.exports = router; 