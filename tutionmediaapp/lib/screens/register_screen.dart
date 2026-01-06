import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../providers/refresh_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _classLevelController = TextEditingController();
  final _locationController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _preferredClassesController = TextEditingController();
  final _preferredSubjectsController = TextEditingController();
  final _bioController = TextEditingController();

  String? _profilePictureBase64;

  String _role = 'STUDENT';
  String _medium = 'Bangla';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _classLevelController.dispose();
    _locationController.dispose();
    _guardianNameController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _preferredClassesController.dispose();
    _preferredSubjectsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // For web, use gallery picker which works better
      final picker = ImagePicker();
      try {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          imageQuality: 85,
        );
        if (image == null) return;

        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);
        if (mounted) {
          setState(() {
            _profilePictureBase64 = base64Image;
          });
        }
      } catch (e) {
        debugPrint('Image picker error: $e');
        _showSnack('Failed to pick image');
      }
    } else {
      // For mobile platforms
      final picker = ImagePicker();
      try {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          imageQuality: 85,
        );
        if (image == null) return;

        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);
        if (mounted) {
          setState(() {
            _profilePictureBase64 = base64Image;
          });
        }
      } catch (e) {
        debugPrint('Image picker error: $e');
        _showSnack('Failed to pick image');
      }
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _locationController.text.isEmpty) {
      _showSnack('Please fill all required fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    if (_role == 'STUDENT') {
      if (_classLevelController.text.isEmpty ||
          _guardianNameController.text.isEmpty) {
        _showSnack('Please fill all student fields');
        return;
      }
    }

    if (_role == 'TEACHER') {
      if (_qualificationController.text.isEmpty ||
          _preferredSubjectsController.text.isEmpty) {
        _showSnack('Please fill all teacher fields');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(
        _emailController.text,
        _passwordController.text,
        _role,
      );

      if (response['userId'] != null) {
        final loginResponse =
            await ApiService.login(_emailController.text, _passwordController.text);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = User.fromJson(loginResponse['user']);

        await authProvider.login(
          user,
          loginResponse['token'],
        );

        // Upload profile picture if selected
        if (_profilePictureBase64 != null) {
          try {
            final picResponse = await ApiService.updateProfilePicture(loginResponse['token'], _profilePictureBase64!);
            debugPrint('Profile picture uploaded: $picResponse');
          } catch (e) {
            debugPrint('Profile picture upload failed: $e');
            // Non-blocking: ignore upload failure here
          }
        }

        // Save profile based on role
        if (_role == 'STUDENT') {
          final profileResponse = await ApiService.createOrUpdateStudentProfile(
            loginResponse['token'],
            {
              'full_name': _fullNameController.text,
              'phone': _phoneController.text,
              'institution': _institutionController.text,
              'class_level': _classLevelController.text,
              'medium': _medium,
              'location': _locationController.text,
              'guardian_name': _guardianNameController.text,
            },
          );
          if (profileResponse['message'] != 'Profile updated successfully') {
            throw 'Student profile creation failed';
          }
          Provider.of<RefreshProvider>(context, listen: false).notifyRefresh();
        } else {
          final profileResponse = await ApiService.createOrUpdateTeacherProfile(
            loginResponse['token'],
            {
              'full_name': _fullNameController.text,
              'phone': _phoneController.text,
              'qualification': _qualificationController.text,
              'institution': _institutionController.text,
              'experience_years': int.tryParse(_experienceYearsController.text),
              'preferred_classes': _preferredClassesController.text,
              'preferred_subjects': _preferredSubjectsController.text,
              'location': _locationController.text,
              'bio': _bioController.text,
            },
          );
          if (profileResponse['message'] != 'Profile updated successfully') {
            throw 'Teacher profile creation failed';
          }
          Provider.of<RefreshProvider>(context, listen: false).notifyRefresh();
        }

        // Redirect to LoginScreen after registration and profile saving
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      _showSnack(e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                          tooltip: 'Go back',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Account',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join as a student or teacher',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Role Selection with enhanced styling
                  Text(
                    'CHOOSE YOUR ROLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'STUDENT',
                            label: Text('Student'),
                            icon: Icon(Icons.school_outlined),
                          ),
                          ButtonSegment(
                            value: 'TEACHER',
                            label: Text('Teacher'),
                            icon: Icon(Icons.history_edu_outlined),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (v) {
                          setState(() => _role = v.first);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Profile Picture Section
                  _buildSectionHeader(context, 'PROFILE PICTURE', Icons.image_outlined),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: colorScheme.primaryContainer,
                              backgroundImage: _profilePictureBase64 != null
                                  ? MemoryImage(base64Decode(_profilePictureBase64!.split(',').last))
                                  : null,
                              child: _profilePictureBase64 == null
                                  ? Icon(Icons.person_rounded, size: 60, color: colorScheme.onPrimaryContainer)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Account Credentials Section
                  _buildSectionHeader(context, 'ACCOUNT CREDENTIALS', Icons.security_outlined),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined),
                        const SizedBox(height: 16),
                        _passwordField(),
                        const SizedBox(height: 16),
                        _confirmPasswordField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Personal Information Section
                  _buildSectionHeader(context, 'PERSONAL INFORMATION', Icons.person_outline),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildField(controller: _fullNameController, label: 'Full Name *', icon: Icons.badge_outlined),
                        const SizedBox(height: 16),
                        _buildField(controller: _phoneController, label: 'Phone Number *', icon: Icons.phone_android_outlined),
                        const SizedBox(height: 16),
                        _buildField(controller: _locationController, label: 'Location *', icon: Icons.location_on_outlined),
                        const SizedBox(height: 16),
                        _buildField(controller: _institutionController, label: 'Institution', icon: Icons.apartment_rounded),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Role Specific Details Section
                  _buildSectionHeader(context, 'ROLE SPECIFIC DETAILS', Icons.people_alt_outlined),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (_role == 'STUDENT') ..._studentFields(),
                        if (_role == 'TEACHER') ..._teacherFields(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Register Button
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Create Account',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // Sign In Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, int lines = 1}) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _passwordField() => _secureField(
    _passwordController,
    'Password',
    Icons.lock_outline,
    _obscurePassword,
    () => setState(() => _obscurePassword = !_obscurePassword),
  );

  Widget _confirmPasswordField() => _secureField(
    _confirmPasswordController,
    'Confirm Password',
    Icons.lock_reset_outlined,
    _obscureConfirmPassword,
    () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
  );

  Widget _secureField(
    TextEditingController c,
    String l,
    IconData i,
    bool obscure,
    VoidCallback toggle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: _inputDecoration(l, i).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  List<Widget> _studentFields() {
    return [
      _buildField(
        controller: _classLevelController,
        label: 'Class Level *',
        icon: Icons.grade_outlined,
      ),
      const SizedBox(height: 16),
      Padding(
        padding: EdgeInsets.zero,
        child: DropdownButtonFormField<String>(
          initialValue: _medium,
          decoration: _inputDecoration('Medium', Icons.language),
          items: const [
            DropdownMenuItem(value: 'Bangla', child: Text('Bangla')),
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'English Version', child: Text('English Version')),
          ],
          onChanged: (v) => setState(() => _medium = v ?? 'Bangla'),
        ),
      ),
      const SizedBox(height: 16),
      _buildField(
        controller: _guardianNameController,
        label: 'Guardian Name *',
        icon: Icons.family_restroom_outlined,
      ),
    ];
  }

  List<Widget> _teacherFields() {
    return [
      _buildField(
        controller: _qualificationController,
        label: 'Qualification *',
        icon: Icons.workspace_premium_outlined,
      ),
      const SizedBox(height: 16),
      _buildField(
        controller: _preferredClassesController,
        label: 'Preferred Classes',
        icon: Icons.class_outlined,
      ),
      const SizedBox(height: 16),
      _buildField(
        controller: _preferredSubjectsController,
        label: 'Preferred Subjects *',
        icon: Icons.subject_outlined,
      ),
      const SizedBox(height: 16),
      _buildField(
        controller: _experienceYearsController,
        label: 'Experience (Years)',
        icon: Icons.timeline_outlined,
      ),
      const SizedBox(height: 16),
      _buildField(
        controller: _bioController,
        label: 'Short Bio',
        icon: Icons.info_outline,
        lines: 3,
      ),
    ];
  }
}
