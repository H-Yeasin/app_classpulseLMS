import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key});

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
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Student Detail",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Student Profile
          _buildProfileSection(),

          const SizedBox(height: 32),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: "Questions",
                  value: "9/10",
                  color: const Color(0xFF4DB68D),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: "Progress",
                  value: "90%",
                  color: const Color(0xFFFFCC33),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            "Questions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),

          _buildQuestionTile(
            number: 1,
            question: "What is 1/2 as a decimal?",
            isSelectedCorrect: true,
            selectedAnswer: "0.5",
            correctAnswer: "0.5",
          ),
          _buildQuestionTile(
            number: 2,
            question: "What is 0.75 as a fraction?",
            isSelectedCorrect: false,
            selectedAnswer: "1/2",
            correctAnswer: "3/4",
            initiallyExpanded: true,
            options: ["3/4", "1/2", "2/5", "5/8"],
          ),
          _buildQuestionTile(
            number: 3,
            question: "What is 7/10 as a decimal?",
            isSelectedCorrect: true,
            selectedAnswer: "0.7",
            correctAnswer: "0.7",
          ),
          _buildQuestionTile(
            number: 4,
            question: "Convert 0.2 into a fraction.",
            isSelectedCorrect: true,
            selectedAnswer: "1/5",
            correctAnswer: "1/5",
          ),
          _buildQuestionTile(
            number: 5,
            question: "Which decimal is equal to 3/4?",
            isSelectedCorrect: true,
            selectedAnswer: "0.75",
            correctAnswer: "0.75",
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            "https://i.pravatar.cc/150?u=mia",
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mia johnson",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Grade 6 - Age 12",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                "+1 301 381 7702",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile({
    required int number,
    required String question,
    required bool isSelectedCorrect,
    required String selectedAnswer,
    required String correctAnswer,
    List<String>? options,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            "$number. $question",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
            ),
          ),
          trailing: isSelectedCorrect
              ? const Icon(Icons.check_circle, color: Color(0xFF4DB68D))
              : initiallyExpanded
              ? const Icon(Icons.keyboard_arrow_up)
              : const Icon(Icons.keyboard_arrow_down),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (options != null) ...[
                    ...List.generate(options.length, (i) {
                      final char = String.fromCharCode(65 + i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "$char. ${options[i]}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                  ],
                  Row(
                    children: [
                      const Text(
                        "Selected Answer: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                      Text(
                        selectedAnswer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        "Correct Answer: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4DB68D),
                        ),
                      ),
                      Text(
                        correctAnswer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
