import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/teacher_role/profile_screen/rewards_badges.dart';
import 'package:opalmer_education/user_role_screen/user_role_screen.dart';
import 'package:opalmer_education/teacher_role/profile_screen/notification_setting.dart';
import 'package:opalmer_education/teacher_role/profile_screen/about_us.dart';
import 'package:opalmer_education/teacher_role/profile_screen/terms_condition.dart';
import 'package:opalmer_education/teacher_role/profile_screen/disput_center.dart';
import 'package:opalmer_education/teacher_role/profile_screen/block_list.dart';
import 'package:opalmer_education/teacher_role/profile_screen/language.dart';
import 'package:opalmer_education/authentication_screen/two_factor_auth_screen.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Image and Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Header Background
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/Home_dashboard_header.png',
                        fit: BoxFit.cover,
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Profile",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_outlined,
                                    color: Color(0xFF871DAD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar Picture
                Positioned(
                  top: 130,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child:
                          user?.avatar != null &&
                              user!.avatar!.startsWith('http')
                          ? Image.network(
                              user.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/profile/olivia.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/profile/olivia.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Name and Email
            const SizedBox(height: 60),
            Text(
              user?.username ?? "Student",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? "no-email@opalmer.com",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),

            // Menu Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuTile(
                    "Rewards/Badges",
                    Icons.workspace_premium_outlined,
                    const RewardsBadgesScreen(),
                  ),
                  _buildMenuTile(
                    "Notifications Settings",
                    Icons.notifications_none_outlined,
                    const NotificationSettingScreen(),
                  ),
                  _buildMenuTile(
                    "Block list",
                    Icons.block_outlined,
                    const BlockListScreen(),
                  ),
                  _buildMenuTile(
                    "Two-Factor Authentication",
                    Icons.verified_user_outlined,
                    const TwoFactorAuthScreen(),
                  ),
                  _buildMenuTile(
                    "Language",
                    Icons.language_outlined,
                    const LanguageScreen(),
                  ),
                  _buildMenuTile(
                    "About Us",
                    Icons.help_outline,
                    const AboutUsScreen(),
                  ),
                  _buildMenuTile(
                    "Terms and Conditions",
                    Icons.description_outlined,
                    const TermsConditionScreen(),
                  ),
                  _buildMenuTile(
                    "Dispute Center",
                    Icons.chat_outlined,
                    const DisputCenterScreen(),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    child: InkWell(
                      onTap: () async {
                        await ref.read(authServiceProvider).logout();
                        ref.read(authStateProvider.notifier).state = null;
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserRoleScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.logout,
                              color: Color(0xFFFF6B6B),
                              size: 24,
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMid.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryMid),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, [Widget? destination]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: const Color(0xFF444444), size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF444444),
          size: 16,
        ),
        onTap: () {
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          }
        },
      ),
    );
  }
}
