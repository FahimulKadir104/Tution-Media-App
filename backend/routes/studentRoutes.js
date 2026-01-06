const express = require('express');
const { createOrUpdateProfile, getProfile, getProfileById } = require('../controllers/studentController');
const auth = require('../middlewares/auth');
const studentOnly = require('../middlewares/studentOnly');
const teacherOnly = require('../middlewares/teacherOnly');

const router = express.Router();

router.post('/profile', auth, studentOnly, createOrUpdateProfile);
router.get('/profile', auth, studentOnly, getProfile);
router.get('/profile/:studentId', auth, teacherOnly, getProfileById);

module.exports = router;