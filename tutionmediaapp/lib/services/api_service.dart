import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Dynamic URL based on platform
  // Web (Chrome, Firefox): http://192.168.43.62:3000 (machine IP)
  // Android Emulator: http://10.0.2.2:3000 (special IP to reach host)
  // iOS/Physical: http://192.168.43.62:3000 (machine IP)
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web - use machine IP
      return 'http://192.168.43.62:3000/api';
    } else if (Platform.isAndroid) {
      // Android Emulator/Device - use special IP
      return 'http://10.0.2.2:3000/api';
    } else {
      // iOS and others - use machine IP
      return 'http://192.168.43.62:3000/api';
    }
  }

  static String get serverUrl {
    if (kIsWeb) {
      return 'http://192.168.43.62:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://192.168.43.62:3000';
    }
  }

  // Auth
  static Future<Map<String, dynamic>> register(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Student Profile
  static Future<Map<String, dynamic>> createOrUpdateStudentProfile(String token, Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getStudentProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getStudentProfileById(String token, int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/profile/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Teacher Profile
  static Future<Map<String, dynamic>> createOrUpdateTeacherProfile(String token, Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teacher/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTeacherProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/teacher/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('TEACHER PROFILE API RESPONSE STATUS: ${response.statusCode}');
    print('TEACHER PROFILE API RESPONSE BODY: ${response.body}');
    if (response.statusCode != 200) {
      throw response.body;
    }
    return jsonDecode(response.body);
  }

  // Posts
  static Future<Map<String, dynamic>> createPost(String token, Map<String, dynamic> postData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(postData),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPosts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deletePost(String token, int postId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePostStatus(String token, int postId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$postId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePost(String token, int postId, Map<String, dynamic> postData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(postData),
    );
    return jsonDecode(response.body);
  }

  // Responses
  static Future<Map<String, dynamic>> respondToPost(String token, int postId, Map<String, dynamic> responseData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/respond'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(responseData),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getResponses(String token, int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/responses'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> hasResponded(String token, int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/hasResponded'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getRespondedPosts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/responded'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Messaging
  static Future<List<dynamic>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> startConversation(String token, int postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$postId/start'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getMessages(String token, int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendMessage(String token, int conversationId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markMessagesAsRead(String token, int conversationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$conversationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Profile Picture
  static Future<Map<String, dynamic>> updateProfilePicture(String token, String profilePictureBase64) async {
    try {
      if (profilePictureBase64.isEmpty) {
        throw Exception('Profile picture data is empty');
      }

      print('Uploading profile picture, token length: ${token.length}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/profile-picture/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'profilePictureBase64': profilePictureBase64}),
      );
      
      print('UPDATE PROFILE PICTURE RESPONSE STATUS: ${response.statusCode}');
      print('UPDATE PROFILE PICTURE RESPONSE BODY: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {'message': 'Profile picture updated successfully'};
        }
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UPDATE PROFILE PICTURE ERROR: $e');
      rethrow;
    }
  }

  static Future<String?> getProfilePicture(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile-picture/$userId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final profilePictureUrl = data['profilePictureUrl'];
      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        // If the URL is a relative path, prepend the server URL
        if (!profilePictureUrl.startsWith('http')) {
          return '$serverUrl$profilePictureUrl';
        }
        return profilePictureUrl;
      }
    }
    return null;
  }
}
