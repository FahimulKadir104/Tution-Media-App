import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/teacher_profile.dart';
import 'dashboard_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _institutionController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _preferredClassesController = TextEditingController();
  final _preferredSubjectsController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isVerified = false;
  bool _isLoading = true;
  String? _profilePictureUrl;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _institutionController.dispose();
    _experienceYearsController.dispose();
    _preferredClassesController.dispose();
    _preferredSubjectsController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    if (mounted) setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null) {
      _finishLoading();
      return;
    }

    try {
      final response = await ApiService.getTeacherProfile(auth.token!);
      debugPrint('Teacher profile response: $response');

      final profilePicture = await ApiService.getProfilePicture(auth.user!.id);

      if (!mounted) return;

      Map<String, dynamic>? profileJson = response['profile'] ?? response;
      debugPrint('Profile JSON: $profileJson');

      if (profileJson == null) {
        debugPrint('Profile JSON is null');
        _finishLoading();
        return;
      }

      final profile = TeacherProfile.fromJson(profileJson);
      debugPrint('Parsed profile: fullName=${profile.fullName}');

      setState(() {
        _fullNameController.text = profile.fullName ?? '';
        _phoneController.text = profile.phone ?? '';
        _qualificationController.text = profile.qualification ?? '';
        _institutionController.text = profile.institution ?? '';
        _experienceYearsController.text =
            profile.experienceYears?.toString() ?? '';
        _preferredClassesController.text =
            profile.preferredClasses ?? '';
        _preferredSubjectsController.text =
            profile.preferredSubjects ?? '';
        _locationController.text = profile.location ?? '';
        _bioController.text = profile.bio ?? '';
        _isVerified = profile.isVerified;
        _profilePictureUrl = profilePicture;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR loading teacher profile: $e');
      _finishLoading();
    }
  }

  void _finishLoading() {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    
    if (image != null) {
      setState(() => _selectedImage = image);
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        // Convert image to base64 using XFile's readAsBytes which works on web
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);
        
        await ApiService.updateProfilePicture(auth.token!, base64Image);
        
        if (!mounted) return;
        
        setState(() => _profilePictureUrl = base64Image);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated'), behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        debugPrint('Image upload error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final profileData = {
      'full_name': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'institution': _institutionController.text.trim(),
      'experience_years':
          int.tryParse(_experienceYearsController.text),
      'preferred_classes':
          _preferredClassesController.text.trim(),
      'preferred_subjects':
          _preferredSubjectsController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'is_verified': _isVerified,
    };

    try {
      await ApiService.createOrUpdateTeacherProfile(
          auth.token!, profileData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Teacher Profile',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          if (_isVerified)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.verified, color: Colors.blue),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: _buildForm(),
            ),
    );
  }

  Widget _buildForm() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: kIsWeb ? 600 : double.infinity),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Profile Picture Section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withOpacity(0.1),
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: _selectedImage != null && !kIsWeb
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.network(
                                        _profilePictureUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 60,
                                            color: colorScheme.primary,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: colorScheme.primary,
                                    ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                              border: Border.all(
                                color: colorScheme.background,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('PERSONAL INFORMATION'),
                const SizedBox(height: 16),
                _field(_fullNameController, 'Full Name',
                    Icons.person_outline, true),
                _field(_phoneController, 'Phone',
                    Icons.phone_android_outlined, true),
                _field(_locationController, 'Location',
                    Icons.map_outlined, true),
                const SizedBox(height: 12),
                _buildSectionHeader('ACADEMIC & EXPERIENCE'),
                const SizedBox(height: 16),
                _field(_qualificationController,
                    'Highest Qualification',
                    Icons.workspace_premium_outlined, true),
                _field(_institutionController, 'Institution',
                    Icons.school_outlined),
                _field(_experienceYearsController,
                    'Years of Experience',
                    Icons.timer_outlined,
                    false,
                    TextInputType.number),
                const SizedBox(height: 12),
                _buildSectionHeader('TUTORING PREFERENCES'),
                const SizedBox(height: 16),
                _field(_preferredSubjectsController,
                    'Preferred Subjects',
                    Icons.book_outlined, true),
                _field(_preferredClassesController,
                    'Preferred Classes',
                    Icons.class_outlined),
                const SizedBox(height: 12),
                _buildSectionHeader('ABOUT ME'),
                const SizedBox(height: 16),
                _field(_bioController, 'Short Bio',
                    Icons.description_outlined,
                    false,
                    TextInputType.text,
                    4),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saveProfile,
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.3,
        color:
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool required = false,
    TextInputType type = TextInputType.text,
    int lines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: type,
        validator:
            required ? (v) => v!.isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
