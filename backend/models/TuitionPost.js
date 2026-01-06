const pool = require('../config/database');

class TuitionPost {
  static async create(studentId, postData) {
    const { subject, class_level, days_per_week, salary, location, description } = postData;
    
    if (!subject || !class_level || !days_per_week || !salary || !location || !description) {
      throw new Error('All fields are required: subject, class_level, days_per_week, salary, location, description');
    }
    
    const [result] = await pool.execute(
      'INSERT INTO tuition_posts (student_id, subject, class_level, days_per_week, salary, location, description, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, \"OPEN\", NOW())',
      [studentId, subject, class_level, days_per_week, salary, location, description]
    );
    return result.insertId;
  }

  static async findById(id) {
    const [rows] = await pool.execute('SELECT * FROM tuition_posts WHERE id = ?', [id]);
    return rows[0];
  }

  static async findByStudentId(studentId) {
    const [rows] = await pool.execute(
      `SELECT p.*, 
       (SELECT COUNT(*) FROM responses r WHERE r.post_id = p.id) AS response_count
       FROM tuition_posts p
       WHERE p.student_id = ?
       ORDER BY p.created_at DESC`,
      [studentId]
    );
    return rows;
  }

  static async findOpenPosts() {
    const [rows] = await pool.execute(
      `SELECT p.*, COALESCE(sp.full_name, u.email) AS student_name, u.email AS student_email,
       (SELECT COUNT(*) FROM responses r WHERE r.post_id = p.id) AS response_count
       FROM tuition_posts p
       LEFT JOIN student_profiles sp ON sp.user_id = p.student_id
       LEFT JOIN users u ON u.id = p.student_id
       WHERE p.status = "OPEN"`
    );
    return rows;
  }

  static async deleteById(id) {
    const [result] = await pool.execute('DELETE FROM tuition_posts WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  static async updateStatus(id, status) {
    const [result] = await pool.execute('UPDATE tuition_posts SET status = ? WHERE id = ?', [status, id]);
    return result.affectedRows > 0;
  }

  static async update(id, postData) {
    const { subject, class_level, days_per_week, salary, location, description } = postData;
    const [result] = await pool.execute(
      'UPDATE tuition_posts SET subject = ?, class_level = ?, days_per_week = ?, salary = ?, location = ?, description = ? WHERE id = ?',
      [subject, class_level, days_per_week, salary, location, description, id]
    );
    return result.affectedRows > 0;
  }
}

module.exports = TuitionPost;