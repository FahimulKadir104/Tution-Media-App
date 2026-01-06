const pool = require('../config/database');

class StudentProfile {
  static async createOrUpdate(userId, profileData) {
    const { full_name, phone, institution, class_level, medium, location, guardian_name } = profileData;
    console.log('StudentProfile.createOrUpdate called with userId:', userId, 'data:', profileData);
    const [result] = await pool.execute(
      `INSERT INTO student_profiles (user_id, full_name, phone, institution, class_level, medium, location, guardian_name)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
       full_name = VALUES(full_name),
       phone = VALUES(phone),
       institution = VALUES(institution),
       class_level = VALUES(class_level),
       medium = VALUES(medium),
       location = VALUES(location),
       guardian_name = VALUES(guardian_name)`,
      [userId, full_name, phone, institution, class_level, medium, location, guardian_name]
    );
    console.log('StudentProfile insert result:', result);
    return result;
  }

  static async findByUserId(userId) {
    const [rows] = await pool.execute('SELECT * FROM student_profiles WHERE user_id = ?', [userId]);
    return rows[0];
  }
}

module.exports = StudentProfile;