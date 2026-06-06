import 'package:flutter/material.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class StudentQuizResultScreen extends StatelessWidget {
  final QuizSubmissionResult result;
  const StudentQuizResultScreen({Key? key, required this.result})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF871DAD), Color(0xFF9D39C3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Celebratory Header
              const Text(
                "Quiz Completed🏆",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You answered ${result.correctCount} out of ${result.totalQuestions} questions correctly",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Score: ${result.percentage.toInt()}%",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Answer Summary
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const Text(
                      "Summary of answers:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...result.answers
                        .map(
                          (ans) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildResultCard(
                              ans.question,
                              ans.selectedAnswer,
                              ans.correctAnswer ?? "N/A",
                              ans.isCorrect,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),

              // Footer Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Back To Quizzes",
                      style: TextStyle(
                        color: Color(0xFF871DAD),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    String question,
    String userAnswer,
    String correctAnswer,
    bool isCorrect,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check : Icons.close,
                color: isCorrect ? const Color(0xFF4AA678) : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "Your answer: $userAnswer",
                style: TextStyle(
                  fontSize: 13,
                  color: isCorrect ? const Color(0xFF4AA678) : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check, color: Color(0xFF4AA678), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Correct answer: $correctAnswer",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4AA678),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
