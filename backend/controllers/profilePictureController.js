const User = require('../models/User');
const fs = require('fs');
const path = require('path');

const updateProfilePicture = async (req, res) => {
  try {
    const userId = req.user.id;
    const { profilePictureBase64 } = req.body;

    if (!profilePictureBase64) {
      return res.status(400).json({ message: 'Profile picture data is required' });
    }

    // Create uploads directory if it doesn't exist
    const uploadsDir = path.join(__dirname, '../uploads/profile_pictures');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Remove data URI prefix if present
    let base64Data = profilePictureBase64;
    if (profilePictureBase64.startsWith('data:image')) {
      base64Data = profilePictureBase64.split(',')[1];
    }

    // Generate filename with userId
    const filename = `profile_${userId}.jpg`;
    const filepath = path.join(uploadsDir, filename);

    // Write file
    fs.writeFileSync(filepath, base64Data, 'base64');

    // Store URL path in database
    const profilePictureUrl = `/uploads/profile_pictures/${filename}`;
    const updated = await User.updateProfilePicture(userId, profilePictureUrl);

    if (!updated) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ 
      message: 'Profile picture updated successfully', 
      profilePictureUrl,
      fullUrl: `${process.env.API_URL || 'http://localhost:3001'}${profilePictureUrl}`
    });
  } catch (error) {
    console.error('Error updating profile picture:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getProfilePicture = async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const profilePictureUrl = await User.getProfilePicture(userId);
    
    res.json({ profilePictureUrl });
  } catch (error) {
    console.error('Error fetching profile picture:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { updateProfilePicture, getProfilePicture };
