import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (kIsWeb) 'dart:html';
import 'dart:convert';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/student_profile.dart';
import 'dashboard_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  StudentProfileScreenState createState() => StudentProfileScreenState();
}

class StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _classLevelController = TextEditingController();
  final _locationController = TextEditingController();
  final _guardianNameController = TextEditingController();

  String _medium = 'Bangla';
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
    _institutionController.dispose();
    _classLevelController.dispose();
    _locationController.dispose();
    _guardianNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final profileData = await ApiService.getStudentProfile(auth.token!);
      debugPrint('Student profile data: $profileData');
      final profileJson = (profileData['profile'] ?? profileData) as Map<String, dynamic>;
      final profile = StudentProfile.fromJson(profileJson);

      final profilePicture = await ApiService.getProfilePicture(auth.user!.id);

      if (!mounted) return;

      setState(() {
        _fullNameController.text = profile.fullName ?? '';
        _phoneController.text = profile.phone ?? '';
        _institutionController.text = profile.institution ?? '';
        _classLevelController.text = profile.classLevel ?? '';
        _locationController.text = profile.location ?? '';
        _guardianNameController.text = profile.guardianName ?? '';
        _medium = profile.medium ?? 'Bangla';
        _profilePictureUrl = profilePicture;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profileData = {
      'full_name': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'institution': _institutionController.text.trim(),
      'class_level': _classLevelController.text.trim(),
      'medium': _medium,
      'location': _locationController.text.trim(),
      'guardian_name': _guardianNameController.text.trim(),
    };

    try {
      await ApiService.createOrUpdateStudentProfile(auth.token!, profileData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully'), behavior: SnackBarBehavior.floating),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: kIsWeb ? 500 : double.infinity),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          _buildSectionHeader(context, 'Personal Information'),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hint: 'Enter your name',
                            icon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          _buildField(
                            controller: _phoneController,
                            label: 'Phone',
                            hint: '+880...',
                            icon: Icons.phone_android_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildSectionHeader(context, 'Academic Details'),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _institutionController,
                            label: 'Institution',
                            hint: 'School/College name',
                            icon: Icons.school_outlined,
                          ),
                          _buildField(
                            controller: _classLevelController,
                            label: 'Class Level',
                            hint: 'e.g., Grade 10',
                            icon: Icons.history_edu_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: _medium,
                            decoration: _inputDecoration('Medium', Icons.translate_outlined),
                            items: ['Bangla', 'English', 'English Version']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (v) => setState(() => _medium = v!),
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(context, 'Guardian & Location'),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _guardianNameController,
                            label: 'Guardian Name',
                            hint: 'Parent/Guardian name',
                            icon: Icons.supervisor_account_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          _buildField(
                            controller: _locationController,
                            label: 'Location',
                            hint: 'Your city/area',
                            icon: Icons.map_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _saveProfile,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, [String? hint]) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: _inputDecoration(label, icon, hint),
      ),
    );
  }
}