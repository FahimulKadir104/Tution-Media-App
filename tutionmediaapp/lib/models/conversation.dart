class Conversation {
  final int id;
  final int studentId;
  final int teacherId;
  final int postId;
  final String? otherUserEmail;
  final String? otherUserName;
  final String? otherUserRole;
  final String? postSubject;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.postId,
    this.otherUserEmail,
    this.otherUserName,
    this.otherUserRole,
    this.postSubject,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      studentId: json['student_id'],
      teacherId: json['teacher_id'],
      postId: json['post_id'],
      otherUserEmail: json['other_user_email'],
      otherUserName: json['other_user_name'],
      otherUserRole: json['other_user_role'],
      postSubject: json['post_subject'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'post_id': postId,
    };
  }
}