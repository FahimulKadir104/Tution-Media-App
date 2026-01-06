const express = require('express');
const { createPost, getPosts, deletePost, updatePostStatus, updatePost } = require('../controllers/postController');
const auth = require('../middlewares/auth');
const studentOnly = require('../middlewares/studentOnly');

const router = express.Router();

router.post('/', auth, studentOnly, createPost);
router.get('/', auth, getPosts);
router.delete('/:id', auth, studentOnly, deletePost);
router.put('/:id/status', auth, studentOnly, updatePostStatus);
router.put('/:id', auth, studentOnly, updatePost);

module.exports = router;