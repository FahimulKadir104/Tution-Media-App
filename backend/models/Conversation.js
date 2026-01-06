const pool = require('../config/database');

class Conversation {
  static async create(studentId, teacherId, postId) {
    const [result] = await pool.execute(
      'INSERT INTO conversations (student_id, teacher_id, post_id, created_at) VALUES (?, ?, ?, NOW())',
      [studentId, teacherId, postId]
    );
    return result.insertId;
  }

  static async findByParticipants(studentId, teacherId, postId) {
    const [rows] = await pool.execute(
      'SELECT * FROM conversations WHERE student_id = ? AND teacher_id = ? AND post_id = ?',
      [studentId, teacherId, postId]
    );
    return rows[0];
  }

  static async findByUserId(userId) {
    const [rows] = await pool.execute(
      `SELECT c.*, u.email as other_user_email, tp.subject as post_subject,
       COALESCE(sp.full_name, tpv.full_name, u.email) as other_user_name,
       m.message as last_message, m.sent_at as last_message_time,
       COALESCE(unread.count, 0) as unread_count
       FROM conversations c
       JOIN tuition_posts tp ON c.post_id = tp.id
       JOIN users u ON (u.id = c.student_id OR u.id = c.teacher_id) AND u.id != ?
       LEFT JOIN student_profiles sp ON sp.user_id = u.id
       LEFT JOIN teacher_profiles tpv ON tpv.user_id = u.id
       LEFT JOIN (
         SELECT conversation_id, message, sent_at
         FROM messages m1
         WHERE sent_at = (
           SELECT MAX(sent_at) 
           FROM messages m2 
           WHERE m1.conversation_id = m2.conversation_id
         )
       ) m ON m.conversation_id = c.id
       LEFT JOIN (
         SELECT conversation_id, COUNT(*) as count
         FROM messages
         WHERE sender_id != ? AND is_read = FALSE
         GROUP BY conversation_id
       ) unread ON unread.conversation_id = c.id
       WHERE c.student_id = ? OR c.teacher_id = ?
       ORDER BY m.sent_at DESC, c.created_at DESC`,
      [userId, userId, userId, userId]
    );
    return rows;
  }
}

module.exports = Conversation;