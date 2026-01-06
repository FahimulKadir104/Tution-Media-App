class TuitionPost {
  final int id;
  final int studentId;
  final String? studentName;
  final String? studentEmail;
  final String? subject;
  final String? classLevel;
  final int? daysPerWeek;
  final double? salary;
  final String? location;
  final String? description;
  final String status;
  final int responseCount;

  TuitionPost({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentEmail,
    this.subject,
    this.classLevel,
    this.daysPerWeek,
    this.salary,
    this.location,
    this.description,
    required this.status,
    this.responseCount = 0,
  });

  factory TuitionPost.fromJson(Map<String, dynamic> json) {
    return TuitionPost(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentEmail: json['student_email'],
      subject: json['subject'],
      classLevel: json['class_level'],
      daysPerWeek: json['days_per_week'],
      salary: json['salary'] != null ? double.parse(json['salary'].toString()) : null,
      location: json['location'],
      description: json['description'],
      status: json['status'],
      responseCount: json['response_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject': subject,
      'class_level': classLevel,
      'days_per_week': daysPerWeek,
      'salary': salary,
      'location': location,
      'description': description,
      'status': status,
    };
  }
}