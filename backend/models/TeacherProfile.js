const pool = require('../config/database');

class TeacherProfile {
  static async createOrUpdate(userId, profileData) {
    const { full_name, phone, qualification, institution, experience_years, preferred_classes, preferred_subjects, location, bio, is_verified = false } = profileData;
    const [result] = await pool.execute(
      `INSERT INTO teacher_profiles (user_id, full_name, phone, qualification, institution, experience_years, preferred_classes, preferred_subjects, location, bio, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
       full_name = VALUES(full_name),
       phone = VALUES(phone),
       qualification = VALUES(qualification),
       institution = VALUES(institution),
       experience_years = VALUES(experience_years),
       preferred_classes = VALUES(preferred_classes),
       preferred_subjects = VALUES(preferred_subjects),
       location = VALUES(location),
       bio = VALUES(bio),
       is_verified = VALUES(is_verified)`,
      [userId, full_name, phone, qualification, institution, experience_years, preferred_classes, preferred_subjects, location, bio, is_verified]
    );
    return result;
  }

  static async findByUserId(userId) {
    const [rows] = await pool.execute('SELECT * FROM teacher_profiles WHERE user_id = ?', [userId]);
    return rows[0];
  }
}

module.exports = TeacherProfile;