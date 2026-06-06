import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/role_provider.dart';
import 'package:opalmer_education/custom_bottom_navigation_bar/main_shell.dart';
import 'package:opalmer_education/parent_role/parent_main_shell.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/profile_setup_screen.dart'
    as parent_profile_setup;
import 'package:opalmer_education/teacher_role/profile_screen/profile_setup.dart'
    as teacher_profile_setup;
import 'package:opalmer_education/student_role/student_main_shell.dart';
import 'package:opalmer_education/parent_role/ParentHomeDashboard/parent_home_dashboard.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final bool isRegistrationFlow;

  const OtpScreen({super.key, this.isRegistrationFlow = false});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleVerificationSuccess() {
    final role = ref.read(roleProvider);

    if (widget.isRegistrationFlow) {
      _routeToProfileSetup(role);
      return;
    }

    _routeToDashboard(role);
  }

  void _routeToProfileSetup(UserRole role) {
    if (role == UserRole.teacher) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const teacher_profile_setup.ProfileSetupScreen(
            isRegistrationFlow: true,
          ),
        ),
      );
    } else if (role == UserRole.parent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const parent_profile_setup.ProfileSetupScreen(
            isRegistrationFlow: true,
          ),
        ),
      );
    }
  }

  void _routeToDashboard(UserRole role) {
    if (role == UserRole.student) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentMainShell()),
        (route) => false,
      );
    } else if (role == UserRole.parent) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ParentMainShell()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Wavy Design
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 350,
                  child: Image.asset(
                    'assets/images/header_design.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF871DAD),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "OTP",
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "OTP just sent to your provided\nemail.",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // OTP Input Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) => _buildOtpCircle(index)),
              ),
            ),

            const SizedBox(height: 40),

            // Resend Code Helper Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't get code? - ",
                  style: TextStyle(fontSize: 15, color: Color(0xFF444444)),
                ),
                GestureDetector(
                  onTap: () {
                    // Resend logic
                  },
                  child: const Text(
                    "Resend code",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF871DAD),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Verify Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Verification logic
                    final role = ref.read(roleProvider);
                    if (role == UserRole.student) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const StudentMainShell(),
                        ),
                        (route) => false,
                      );
                    } else if (role == UserRole.parent) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const ParentHomeDashboard(),
                        ),
                        (route) => false,
                      );
                    } else {
                      // Default to teacher / main shell
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF871DAD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "VERIFY",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildOtpCircle(int index) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          maxLength: 1,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF871DAD),
          ),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
