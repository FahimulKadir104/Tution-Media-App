const StudentProfile = require('../models/StudentProfile');
const User = require('../models/User');

const createOrUpdateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const profileData = req.body;

    console.log('Creating student profile for userId:', userId);
    console.log('Profile data:', profileData);

    await StudentProfile.createOrUpdate(userId, profileData);

    console.log('Student profile created/updated successfully');
    res.json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Error creating student profile:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const profile = await StudentProfile.findByUserId(userId);

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    res.json({ profile });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getProfileById = async (req, res) => {
  try {
    const studentId = req.params.studentId;

    const profile = await StudentProfile.findByUserId(studentId);
    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    const user = await User.findById(studentId);

    res.json({ profile, email: user?.email });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { createOrUpdateProfile, getProfile, getProfileById };