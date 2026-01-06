const pool = require('../config/database');

class Message {
  static async create(conversationId, senderId, message) {
    const [result] = await pool.execute(
      'INSERT INTO messages (conversation_id, sender_id, message, sent_at) VALUES (?, ?, ?, NOW())',
      [conversationId, senderId, message]
    );
    return result.insertId;
  }

  static async findByConversationId(conversationId) {
    const [rows] = await pool.execute(
      `SELECT m.*, u.email as sender_email, u.role as sender_role,
       COALESCE(sp.full_name, tpv.full_name, u.email) as sender_name
       FROM messages m
       JOIN users u ON m.sender_id = u.id
       LEFT JOIN student_profiles sp ON sp.user_id = u.id
       LEFT JOIN teacher_profiles tpv ON tpv.user_id = u.id
       WHERE m.conversation_id = ?
       ORDER BY m.sent_at ASC`,
      [conversationId]
    );
    return rows;
  }

  static async markAsRead(conversationId, userId) {
    await pool.execute(
      'UPDATE messages SET is_read = TRUE WHERE conversation_id = ? AND sender_id != ? AND is_read = FALSE',
      [conversationId, userId]
    );
  }
}

module.exports = Message;