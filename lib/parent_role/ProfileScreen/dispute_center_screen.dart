import 'package:flutter/material.dart';
import 'package:opalmer_education/parent_role/ProfileScreen/models/support_screen.dart';

class ParentDisputeCenterScreen extends StatefulWidget {
  const ParentDisputeCenterScreen({super.key});

  @override
  State<ParentDisputeCenterScreen> createState() =>
      _ParentDisputeCenterScreenState();
}

class _ParentDisputeCenterScreenState extends State<ParentDisputeCenterScreen> {
  // Track which FAQ is currently expanded. -1 means none.
  int _expandedIndex = 0;

  final List<Map<String, String>> _faqs = [
    {
      "question": "Who is this app for?",
      "answer":
          "Our platform is designed for schools, educators, students, and parents looking to improve communication, streamline",
    },
    {
      "question": "How do parents stay involved?",
      "answer":
          "Parents can track academic progress and behavior in real-time.",
    },
    {
      "question": "Is the app mobile-friendly?",
      "answer":
          "Yes, our app is fully optimized for both iOS and Android devices.",
    },
    {
      "question": "How is data kept secure?",
      "answer": "We use industry-standard encryption to protect all user data.",
    },
    {
      "question": "What kind of reports can be generated?",
      "answer":
          "You can generate detailed academic, behavioral, and attendance reports.",
    },
    {
      "question": "How do we get started?",
      "answer": "Simply create an account and follow the onboarding steps.",
    },
    {
      "question": "Is there a cost to use the app?",
      "answer": "We offer tiered pricing plans including a basic free tier.",
    },
    {
      "question": "What support options are available?",
      "answer": "24/7 dedicated support via in-app chat or email.",
    },
  ];

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
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ),
        title: const Text(
          "Dispute Center",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 20),
        //     child: Center(
        //       child: GestureDetector(
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => const SupportScreen(),
        //             ),
        //           );
        //         },
        //         child: Container(
        //           width: 40,
        //           height: 40,
        //           decoration: const BoxDecoration(
        //             color: Color(0xFF871DAD),
        //             shape: BoxShape.circle,
        //           ),
        //           child: const Icon(
        //             Icons.chat_bubble_outline,
        //             color: Colors.white,
        //             size: 20,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // App Features Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "App Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Cards ListView
              SizedBox(
                height: 130, // Increased height to prevent bottom overflow
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFeatureCard(
                      "Grading & Assessments",
                      "Streamline evaluations with\ncustomizable grading tools and instant.",
                    ),
                    const SizedBox(width: 16),
                    _buildFeatureCard(
                      "Swift Communication",
                      "Experience fast, reliable messaging\n—right at your fingertips.",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // FAQs Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // FAQs List
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return _buildFAQItem(
                    index,
                    _faqs[index]["question"]!,
                    _faqs[index]["answer"]!,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: const Color(0xFF871DAD)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, String question, String answer) {
    bool isExpanded = _expandedIndex == index;

    return Column(
      children: [
        Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 16),
            initiallyExpanded: index == 0, // Mockup has first one open
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedIndex = index;
                } else if (_expandedIndex == index) {
                  _expandedIndex = -1;
                }
              });
            },
            title: Text(
              question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF871DAD),
              ),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF871DAD),
                size: 16,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
