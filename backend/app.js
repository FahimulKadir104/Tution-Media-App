const express = require('express');
const cors = require('cors'); // assuming we need cors for Flutter
const path = require('path');
require('dotenv').config();

console.log('DB_HOST:', process.env.DB_HOST);
console.log('DB_USER:', process.env.DB_USER);
console.log('DB_PASSWORD:', process.env.DB_PASSWORD ? '***' : 'not set');
console.log('DB_NAME:', process.env.DB_NAME);

const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const teacherRoutes = require('./routes/teacherRoutes');
const postRoutes = require('./routes/postRoutes');
const responseRoutes = require('./routes/responseRoutes');
const messageRoutes = require('./routes/messageRoutes');
const profilePictureRoutes = require('./routes/profilePictureRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/teacher', teacherRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/posts', responseRoutes);
app.use('/api/messages', messageRoutes); // since responses are under posts/:postId
app.use('/api/profile-picture', profilePictureRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

module.exports = app;