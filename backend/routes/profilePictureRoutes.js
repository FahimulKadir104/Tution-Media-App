const express = require('express');
const { updateProfilePicture, getProfilePicture } = require('../controllers/profilePictureController');
const auth = require('../middlewares/auth');

const router = express.Router();

// Update profile picture (authenticated)
router.put('/update', auth, updateProfilePicture);

// Get profile picture by user ID
router.get('/:userId', getProfilePicture);

module.exports = router;
