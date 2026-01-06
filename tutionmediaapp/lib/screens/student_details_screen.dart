import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/student_profile.dart';

class StudentDetailsScreen extends StatefulWidget {
  final int studentId;
  final String? studentName;

  const StudentDetailsScreen({super.key, required this.studentId, this.studentName});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  StudentProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final data = await ApiService.getStudentProfileById(auth.token!, widget.studentId);
      final profileJson = (data['profile'] ?? data) as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        if (profileJson != null) {
          _profile = StudentProfile.fromJson(profileJson);
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.studentName ?? 'Student Details'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Student info not available', style: textTheme.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      _headerCard(colorScheme, textTheme),
                      const SizedBox(height: 16),
                      _infoTile('Institution', _profile!.institution ?? '--', Icons.school_outlined, colorScheme),
                      _infoTile('Class Level', _profile!.classLevel ?? '--', Icons.history_edu_outlined, colorScheme),
                      _infoTile('Medium', _profile!.medium ?? '--', Icons.translate_outlined, colorScheme),
                      _infoTile('Location', _profile!.location ?? '--', Icons.map_outlined, colorScheme),
                      _infoTile('Guardian', _profile!.guardianName ?? '--', Icons.family_restroom_outlined, colorScheme),
                    ],
                  ),
                ),
    );
  }

  Widget _headerCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.1),
            child: Text(
              (_profile?.fullName ?? widget.studentName ?? 'S')[0].toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.fullName ?? widget.studentName ?? 'Student',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Class: ${_profile?.classLevel ?? '--'} | Medium: ${_profile?.medium ?? '--'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
