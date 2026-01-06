const express = require('express');
const { getConversations, startConversation, getMessages, sendMessage, markMessagesAsRead } = require('../controllers/messageController');
const auth = require('../middlewares/auth');

const router = express.Router();

router.get('/', auth, getConversations);
router.post('/:postId/start', auth, startConversation);
router.get('/:conversationId/messages', auth, getMessages);
router.post('/:conversationId/messages', auth, sendMessage);
router.put('/:conversationId/read', auth, markMessagesAsRead);

module.exports = router;
