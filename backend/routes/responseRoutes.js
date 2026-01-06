const express = require('express');
const { respondToPost, getResponses, hasResponded, getRespondedPosts } = require('../controllers/responseController');
const auth = require('../middlewares/auth');
const teacherOnly = require('../middlewares/teacherOnly');
const studentOnly = require('../middlewares/studentOnly');

const router = express.Router();

router.post('/:postId/respond', auth, teacherOnly, respondToPost);
router.get('/:postId/responses', auth, studentOnly, getResponses);
router.get('/:postId/hasResponded', auth, teacherOnly, hasResponded);
router.get('/responded', auth, teacherOnly, getRespondedPosts);

module.exports = router;