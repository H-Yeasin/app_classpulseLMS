import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMid,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "At Education, we believe education thrives when everyone—teachers, students, and parents—are connected, informed, and empowered. Our platform is built to transform the way schools manage learning by simplifying communication, streamlining classroom management, and strengthening the partnership between home and school.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF777777),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      "Our Mission",
                      "To create a seamless digital environment that supports academic excellence, fosters student growth, and enhances transparency and collaboration across the entire education ecosystem.",
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "What We Do",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We provide an all-in-one education management solution that brings together everything schools need in one intuitive platform. From real-time communication and interactive learning tools to behavior tracking, grading, and performance reporting, we give educators, students, and parents a single space to engage meaningfully with the learning journey.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF777777),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Key Features Include:",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem("📚", "Curriculum & Lesson Planning", "Organize and share structured learning plans."),
                    _buildFeatureItem("👨‍🎓", "Grading & Assessment Tools", "Simplify evaluations and give immediate feedback."),
                    _buildFeatureItem("📊", "Performance Insights", "Track student progress in real time with smart analytics."),
                    _buildFeatureItem("💬", "Communication Channels", "Enable secure messaging between teachers, students, and parents."),
                    _buildFeatureItem("✅", "Behavior Tracking", "Encourage positive behavior with transparent reporting."),
                    _buildFeatureItem("🏠", "School-Home Collaboration", "Keep parents engaged and informed every step of the way."),

                    const SizedBox(height: 24),
                    _buildSection(
                      "Why It Matters",
                      "We’re here to reduce administrative burden, foster deeper engagement, and make education more personal and impactful. Our platform empowers teachers to focus on teaching, students to take ownership of their learning, and parents to stay actively involved—building a stronger, more supportive academic community.",
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      "Our Vision",
                      "To shape the future of education by building smarter, more connected schools where every student has the opportunity to succeed.",
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF777777),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF777777), height: 1.4),
                children: [
                  TextSpan(
                    text: "$title – ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF555555)),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
