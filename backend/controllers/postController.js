const TuitionPost = require('../models/TuitionPost');

const createPost = async (req, res) => {
  try {
    const studentId = req.user.id;
    const postData = req.body;

    console.log('Creating post with data:', postData);
    console.log('Student ID:', studentId);

    const postId = await TuitionPost.create(studentId, postData);

    res.status(201).json({ message: 'Post created successfully', postId });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

const getPosts = async (req, res) => {
  try {
    let posts;
    if (req.user.role === 'TEACHER') {
      posts = await TuitionPost.findOpenPosts();
    } else {
      posts = await TuitionPost.findByStudentId(req.user.id);
    }

    res.json(posts);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const deletePost = async (req, res) => {
  try {
    const postId = req.params.id;
    const post = await TuitionPost.findById(postId);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.student_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const deleted = await TuitionPost.deleteById(postId);
    if (!deleted) {
      return res.status(404).json({ message: 'Post not found' });
    }

    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const updatePostStatus = async (req, res) => {
  try {
    const postId = req.params.id;
    const { status } = req.body;

    if (!['OPEN', 'CLOSED'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status. Must be OPEN or CLOSED' });
    }

    const post = await TuitionPost.findById(postId);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.student_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }

    await TuitionPost.updateStatus(postId, status);
    res.json({ message: 'Post status updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const updatePost = async (req, res) => {
  try {
    const postId = req.params.id;
    const postData = req.body;

    const post = await TuitionPost.findById(postId);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.student_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }

    await TuitionPost.update(postId, postData);
    res.json({ message: 'Post updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { createPost, getPosts, deletePost, updatePostStatus, updatePost };