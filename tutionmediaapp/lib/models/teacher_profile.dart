class TeacherProfile {
  final int id;
  final int userId;
  final String? fullName;
  final String? phone;
  final String? qualification;
  final String? institution;
  final int? experienceYears;
  final String? preferredClasses;
  final String? preferredSubjects;
  final String? location;
  final String? bio;
  final bool isVerified;

  TeacherProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.qualification,
    this.institution,
    this.experienceYears,
    this.preferredClasses,
    this.preferredSubjects,
    this.location,
    this.bio,
    required this.isVerified,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      qualification: json['qualification'],
      institution: json['institution'],
      experienceYears: json['experience_years'],
      preferredClasses: json['preferred_classes'],
      preferredSubjects: json['preferred_subjects'],
      location: json['location'],
      // expected_salary removed
      bio: json['bio'],
      isVerified: (json['is_verified'] == 1 || json['is_verified'] == true) ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'qualification': qualification,
      'institution': institution,
      'experience_years': experienceYears,
      'preferred_classes': preferredClasses,
      'preferred_subjects': preferredSubjects,
      'location': location,
      'bio': bio,
      'is_verified': isVerified,
    };
  }
}