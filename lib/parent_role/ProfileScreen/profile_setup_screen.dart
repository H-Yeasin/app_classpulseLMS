import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opalmer_education/authentication_screen/registration_successful_screen.dart';
import 'package:opalmer_education/core/models/user_model.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/animated_wave_header.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isRegistrationFlow;

  const ProfileSetupScreen({super.key, this.isRegistrationFlow = false});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  File? _pickedImage;
  bool _isSaving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _prefill(UserModel? user) {
    if (_prefilled || user == null) return;
    _nameController.text = user.username;
    _phoneController.text = user.phoneNumber ?? '';
    _emailController.text = user.email ?? '';
    _prefilled = true;
  }

  Future<void> _showPickerSheet() async {
    // Unfocus any active text fields to prevent keyboard/modal interaction freezes
    FocusManager.instance.primaryFocus?.unfocus();

    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryMid,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primaryMid,
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    // IMPORTANT: Wait for the bottom sheet dismissal animation to fully complete
    // before asking iOS to present the native UIImagePickerController.
    // Without this delay, the iOS application context can freeze on the Simulator.
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final picked = await _picker.pickImage(
        source: choice,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _saveChanges() async {
    final user = ref.read(authStateProvider);
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to update your profile.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final formData = FormData.fromMap({
        'username': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: _pickedImage!.path.split('/').last,
          ),
      });

      final response = await _api.dio.put(
        '/users/${user.id}',
        data: formData,
      );

      if (response.data is! Map || response.data['success'] != true) {
        throw Exception(
          response.data is Map
              ? (response.data['message'] ?? 'Update failed')
              : 'Update failed',
        );
      }

      final updated = UserModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );

      ref.read(authStateProvider.notifier).state = updated;
      await _storage.saveUserData(jsonEncode(updated.toJson()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      if (widget.isRegistrationFlow) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RegistrationSuccessfulScreen(),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Profile update failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider _avatarImage(UserModel? user) {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    final url = user?.avatar;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return const NetworkImage(
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    _prefill(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Section ──
            Stack(
              children: [
                const AnimatedWaveHeader(height: 280),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Profile Setup",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.primaryMid,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Complete your profile to connect with your students and school.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Profile Photo Section ──
            GestureDetector(
              onTap: _isSaving ? null : _showPickerSheet,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryMid, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _avatarImage(user),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMid,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Form Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Name",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    icon: Icons.person_outline_rounded,
                    hint: "Enter your name",
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Contact",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    icon: Icons.phone_outlined,
                    hint: "Enter your phone number",
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    icon: Icons.email_outlined,
                    hint: "Enter your email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // ── Action Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMid,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final borderRadius = BorderRadius.circular(12);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 24),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}
