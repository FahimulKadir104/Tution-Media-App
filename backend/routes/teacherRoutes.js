const express = require('express');
const { createOrUpdateProfile, getProfile } = require('../controllers/teacherController');
const auth = require('../middlewares/auth');
const teacherOnly = require('../middlewares/teacherOnly');

const router = express.Router();

router.post('/profile', auth, teacherOnly, createOrUpdateProfile);
router.get('/profile', auth, teacherOnly, getProfile);

module.exports = router;