import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/authentication_screen/login_screen.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/primary_button.dart';
import 'package:opalmer_education/core/providers/role_provider.dart';

class UserRoleScreen extends ConsumerStatefulWidget {
  final bool isRegistrationFlow;

  const UserRoleScreen({super.key, this.isRegistrationFlow = false});

  @override
  ConsumerState<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends ConsumerState<UserRoleScreen>
    with SingleTickerProviderStateMixin {
  String selectedRole = 'Teacher';
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, String>> roles = const [
    {'role': 'Teacher', 'emoji': '👩‍🏫', 'desc': 'Manage classes & students'},
    {
      'role': 'Parent',
      'emoji': '👨‍👩‍👧',
      'desc': 'Track your child\'s progress',
    },
    {'role': 'Student', 'emoji': '👨‍🎓', 'desc': 'Learn and grow every day'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    // Save role to Riverpod
    ref.read(roleProvider.notifier).setRoleFromString(selectedRole);

    // Navigate to Login
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(isRegistrationFlow: widget.isRegistrationFlow),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryVeryLight,
      body: Stack(
        children: [
          // ── Header background image ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/header_design.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Title — same as Figma: bold, large, white
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Account Type",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Choose your role to access the right\nfeatures.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // Role Cards
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            for (int i = 0; i < roles.length; i++) ...[
                              _buildRoleCard(
                                role: roles[i]['role']!,
                                emoji: roles[i]['emoji']!,
                                desc: roles[i]['desc']!,
                                index: i,
                              ),
                              if (i < roles.length - 1)
                                const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: PrimaryButton(
                    text: "CONTINUE",
                    onPressed: _onContinue,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String emoji,
    required String desc,
    required int index,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryMid : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryMid.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppColors.surfaceGradient : null,
                color: isSelected ? null : const Color(0xFFF0EAF8),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),

            const SizedBox(width: 16),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isSelected
                          ? AppColors.primaryMid.withValues(alpha: 0.8)
                          : Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryMid,
                            AppColors.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
