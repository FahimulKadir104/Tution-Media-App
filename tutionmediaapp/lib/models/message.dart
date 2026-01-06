class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String message;
  final String sentAt;
  final String? senderEmail;
  final String? senderName;
  final String? senderRole;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    this.senderEmail,
    this.senderName,
    this.senderRole,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      message: json['message'],
      sentAt: json['sent_at'],
      senderEmail: json['sender_email'],
      senderName: json['sender_name'],
      senderRole: json['sender_role'],
    );
  }

  get content => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': message,
      'sent_at': sentAt,
    };
  }
}