class Response {
  final int id;
  final int postId;
  final int teacherId;
  final double? proposedSalary;
  final String? message;
  final String status;
  final String? teacherName;
  final String? teacherEmail;
  final String? profilePictureUrl;

  Response({
    required this.id,
    required this.postId,
    required this.teacherId,
    this.proposedSalary,
    this.message,
    required this.status,
    this.teacherName,
    this.teacherEmail,
    this.profilePictureUrl,
  });

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      id: json['id'],
      postId: json['post_id'],
      teacherId: json['teacher_id'],
      proposedSalary: json['proposed_salary'] != null ? double.parse(json['proposed_salary'].toString()) : null,
      message: json['message'],
      status: json['status'],
      teacherName: json['teacher_name'],
      teacherEmail: json['teacher_email'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'teacher_id': teacherId,
      'proposed_salary': proposedSalary,
      'message': message,
      'status': status,
      'teacher_name': teacherName,
      'teacher_email': teacherEmail,
      'profile_picture_url': profilePictureUrl,
    };
  }
}