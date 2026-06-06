import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF871DAD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "About Us",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildParagraph(
                "At Education, we believe education thrives when everyone—teachers, students, and parents—are connected, informed, and empowered. Our platform is built to transform the way schools manage learning by simplifying communication, streamlining classroom management, and strengthening the partnership between home and school.",
              ),
              const SizedBox(height: 24),
              _buildHeading("Our Mission"),
              _buildParagraph(
                "To create a seamless digital environment that supports academic excellence, fosters student growth, and enhances transparency and collaboration across the entire education ecosystem.",
              ),
              const SizedBox(height: 24),
              _buildHeading("What We Do"),
              _buildParagraph(
                "We provide an all-in-one education management solution that brings together everything schools need in one intuitive platform. From real-time communication and interactive learning tools to behavior tracking, grading, and performance reporting, we give educators, students, and parents a single space to engage meaningfully with the learning journey.\nKey Features Include:",
              ),
              const SizedBox(height: 8),
              _buildBulletedList(),
              const SizedBox(height: 24),
              _buildHeading("Why It Matters"),
              _buildParagraph(
                 "We're here to reduce administrative burden, foster",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF666666),
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletItem("📚", "Curriculum & Lesson Planning", "Organize and share structured learning plans."),
        _buildBulletItem("👩‍🏫", "Grading & Assessment Tools", "Simplify evaluations and give immediate feedback."),
        _buildBulletItem("📊", "Performance Insights", "Track student progress in real time with smart analytics."),
        _buildBulletItem("💬", "Communication Channels", "Enable secure messaging between teachers, students, and parents."),
        _buildBulletItem("✅", "Behavior Tracking", "Encourage positive behavior with transparent reporting."),
        _buildBulletItem("🏫", "School-Home Collaboration", "Keep parents engaged and informed every step of the way."),
      ],
    );
  }

  Widget _buildBulletItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(" •  ", style: TextStyle(color: Color(0xFF666666), fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, height: 1.5),
                children: [
                  TextSpan(text: "$emoji "),
                  TextSpan(
                    text: "$title – ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
