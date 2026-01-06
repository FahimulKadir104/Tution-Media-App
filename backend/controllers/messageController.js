const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const TuitionPost = require('../models/TuitionPost');

const getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const conversations = await Conversation.findByUserId(userId);
    res.json(conversations);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const startConversation = async (req, res) => {
  try {
    const { postId } = req.params;
    const post = await TuitionPost.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    let conversation = await Conversation.findByParticipants(post.student_id, req.user.id, postId);
    if (!conversation) {
      const conversationId = await Conversation.create(post.student_id, req.user.id, postId);
      conversation = { id: conversationId };
    }

    res.json({ conversationId: conversation.id });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const messages = await Message.findByConversationId(conversationId);
    res.json(messages);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const sendMessage = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { message } = req.body;
    const senderId = req.user.id;

    const messageId = await Message.create(conversationId, senderId, message);
    res.status(201).json({ messageId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const markMessagesAsRead = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    await Message.markAsRead(conversationId, userId);
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { getConversations, startConversation, getMessages, sendMessage, markMessagesAsRead };