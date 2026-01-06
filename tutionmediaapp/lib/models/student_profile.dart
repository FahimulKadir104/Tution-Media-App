class StudentProfile {
  final int id;
  final int userId;
  final String? fullName;
  final String? phone;
  final String? institution;
  final String? classLevel;
  final String? medium;
  final String? location;
  final String? guardianName;

  StudentProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.institution,
    this.classLevel,
    this.medium,
    this.location,
    this.guardianName,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      institution: json['institution'],
      classLevel: json['class_level'],
      medium: json['medium'],
      location: json['location'],
      guardianName: json['guardian_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'institution': institution,
      'class_level': classLevel,
      'medium': medium,
      'location': location,
      'guardian_name': guardianName,
    };
  }
}