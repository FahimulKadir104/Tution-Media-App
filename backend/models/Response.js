const pool = require('../config/database');

class Response {
  static async create(postId, teacherId, responseData) {
    const { proposed_salary, message } = responseData;
    
    // Validate required fields
    if (!message) {
      throw new Error('Message is required for response');
    }
    
    const [result] = await pool.execute(
      'INSERT INTO responses (post_id, teacher_id, proposed_salary, message, status, created_at) VALUES (?, ?, ?, ?, "PENDING", NOW())',
      [postId, teacherId, proposed_salary || null, message]
    );
    return result.insertId;
  }

  static async findByPostId(postId) {
    const [rows] = await pool.execute(
      `SELECT r.*, 
              COALESCE(tp.full_name, u.email) AS teacher_name,
              u.email AS teacher_email,
              u.profile_picture_url
         FROM responses r
         JOIN users u ON u.id = r.teacher_id
         LEFT JOIN teacher_profiles tp ON tp.user_id = r.teacher_id
        WHERE r.post_id = ?`,
      [postId]
    );
    return rows;
  }

  static async hasResponded(postId, teacherId) {
    const [rows] = await pool.execute('SELECT id FROM responses WHERE post_id = ? AND teacher_id = ?', [postId, teacherId]);
    return rows.length > 0;
  }

  static async findPostsByTeacher(teacherId) {
    const [rows] = await pool.execute(
      `SELECT p.*, COALESCE(sp.full_name, u.email) AS student_name, u.email AS student_email
       FROM tuition_posts p
       JOIN responses r ON p.id = r.post_id
       LEFT JOIN student_profiles sp ON sp.user_id = p.student_id
       LEFT JOIN users u ON u.id = p.student_id
       WHERE r.teacher_id = ?`,
      [teacherId]
    );
    return rows;
  }

  static async updateStatus(id, status) {
    const [result] = await pool.execute('UPDATE responses SET status = ? WHERE id = ?', [status, id]);
    return result.affectedRows > 0;
  }
}

module.exports = Response;