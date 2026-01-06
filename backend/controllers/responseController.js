const Response = require('../models/Response');
const TuitionPost = require('../models/TuitionPost');
const User = require('../models/User');

const respondToPost = async (req, res) => {
  try {
    const postId = req.params.postId;
    const teacherId = req.user.id;
    const responseData = req.body;

    console.log('Teacher responding to post:', { postId, teacherId, responseData });

    const post = await TuitionPost.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.status !== 'OPEN') {
      return res.status(400).json({ message: 'Post is not open for responses' });
    }

    const alreadyResponded = await Response.hasResponded(postId, teacherId);
    if (alreadyResponded) {
      return res.status(400).json({ message: 'You have already responded to this post' });
    }

    const responseId = await Response.create(postId, teacherId, responseData);

    res.status(201).json({ message: 'Response submitted successfully', responseId });
  } catch (error) {
    console.error('Error responding to post:', error);
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

const getResponses = async (req, res) => {
  try {
    const postId = req.params.postId;
    const post = await TuitionPost.findById(postId);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.student_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const responses = await Response.findByPostId(postId);

    res.json(responses);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const hasResponded = async (req, res) => {
  try {
    const postId = req.params.postId;
    const teacherId = req.user.id;

    const hasResponded = await Response.hasResponded(postId, teacherId);

    res.json({ hasResponded });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getRespondedPosts = async (req, res) => {
  try {
    const teacherId = req.user.id;

    const posts = await Response.findPostsByTeacher(teacherId);

    res.json(posts);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { respondToPost, getResponses, hasResponded, getRespondedPosts };