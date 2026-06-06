import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/authentication_screen/two_factor_auth_screen.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/animated_wave_header.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/dispute_center_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/profile_setup_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/notification_settings_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/block_list_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/terms_and_condition_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/language_selection_screen.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/about_us_screen.dart';
import 'package:opalmer_education/user_role_screen/user_role_screen.dart';

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  ConsumerState<ParentProfileScreen> createState() =>
      _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // ── Header & Profile Image ──
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const AnimatedWaveHeader(height: 200),
              ClipPath(
                clipper: ProfileHeaderClipper(),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: AppColors.primaryMid,
                  padding: const EdgeInsets.only(top: 75, left: 20, right: 20),
                  alignment: Alignment.topLeft,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Notification bell
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Image.asset(
                            'assets/images/home_dashboard/notification.png',
                            height: 24,
                            width: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Overlapping Avatar
              Positioned(
                top: 130, // Adjust based on header height and avatar size
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage:
                        user?.avatar != null && user!.avatar!.isNotEmpty
                        ? NetworkImage(user.avatar!)
                        : const AssetImage('assets/images/profile/parent.png'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 80), // Space for overlapping avatar
          // ── Name & Email ──
          Text(
            user?.username ?? 'User',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Settings Menu ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: "Edit Profile",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileSetupScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: "Notifications Settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.block_flipped,
                          title: "Block list",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BlockListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.verified_user_outlined,
                          title: "Two-Factor Authentication",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TwoFactorAuthScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.language_rounded,
                          title: "Language",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LanguageSelectionScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: "About Us",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutUsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.assignment_outlined,
                          title: "Terms and Conditions",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TermsAndConditionScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: "Dispute Center",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ParentDisputeCenterScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF444444), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF444444),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          await ref.read(authServiceProvider).logout();
          ref.read(authStateProvider.notifier).state = null;
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UserRoleScreen()),
            (route) => false,
          );
        },
        child: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFFF7070), size: 24),
            SizedBox(width: 16),
            Text(
              "Logout",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF7070),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);

    // Create a smooth wave
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(
      size.width - (size.width / 3.25),
      size.height - 65,
    );
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
