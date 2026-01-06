const pool = require('../config/database');

class User {
  static async create(email, hashedPassword, role) {
    const [result] = await pool.execute(
      'INSERT INTO users (email, password, role, is_verified, created_at) VALUES (?, ?, ?, false, NOW())',
      [email, hashedPassword, role]
    );
    return result.insertId;
  }

  static async findByEmail(email) {
    const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0];
  }

  static async findById(id) {
    const [rows] = await pool.execute('SELECT id, email, role, is_verified, profile_picture_url, created_at FROM users WHERE id = ?', [id]);
    return rows[0];
  }

  static async updateProfilePicture(userId, profilePictureUrl) {
    const [result] = await pool.execute(
      'UPDATE users SET profile_picture_url = ? WHERE id = ?',
      [profilePictureUrl, userId]
    );
    return result.affectedRows > 0;
  }

  static async getProfilePicture(userId) {
    const [rows] = await pool.execute('SELECT profile_picture_url FROM users WHERE id = ?', [userId]);
    return rows[0]?.profile_picture_url || null;
  }
}

module.exports = User;