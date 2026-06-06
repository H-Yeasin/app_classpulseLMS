import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';
import 'package:opalmer_education/core/providers/navigation_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/student_role/Subjects/subjects_screen.dart';
import 'package:opalmer_education/student_role/Subjects/widgets/subject_card.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/student_role/Quizzes/student_quiz_questions_screen.dart';

class StudentHomeDashboard extends ConsumerWidget {
  const StudentHomeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final studentName = user?.username ?? "Student";

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, studentName),
            const SizedBox(height: 10),
            _buildSectionHeader(context, ref, "Classes"),
            const SizedBox(height: 16),
            _buildClassesList(ref),
            const SizedBox(height: 32),
            _buildSectionHeader(context, ref, "Quizzes"),
            const SizedBox(height: 16),
            _buildQuizzesList(ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String studentName) {
    return Stack(
      children: [
        // Wave Background
        Container(
          width: double.infinity,
          height: 220,
          child: Image.asset(
            'assets/images/Home_dashboard_header.png',
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay to match the image precisely if needed,
        // but the asset should already have it.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, $studentName 👋",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your learning starts here.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                // Notification Bell
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              if (title == "Classes") {
                ref.read(studentTabIndexProvider.notifier).state = 1;
              } else if (title == "Quizzes") {
                ref.read(studentTabIndexProvider.notifier).state = 3;
              }
            },
            child: const Text(
              "View All",
              style: TextStyle(
                color: AppColors.primaryMid,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList(WidgetRef ref) {
    final classesAsync = ref.watch(studentClassesProvider);

    return SizedBox(
      height: 220,
      child: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text("No classes found"));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: classes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final studentClass = classes[index];
              return SubjectCard(
                studentClass: studentClass,
                subjectName: studentClass.subject,
                lesson: null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          if (err.toString().contains('401')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  const SizedBox(height: 8),
                  const Text('Session expired. Please log in again.', style: TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: () {
                      ref.read(authServiceProvider).logout();
                      ref.read(authStateProvider.notifier).state = null;
                    },
                    child: const Text('Log Out'),
                  )
                ],
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to load classes. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizzesList(WidgetRef ref) {
    final quizzesAsync = ref.watch(studentQuizzesProvider);
    final resultsAsync = ref.watch(studentQuizResultsProvider);

    return quizzesAsync.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("No quizzes available", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final results = resultsAsync.asData?.value ?? [];

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quizzes.length > 3 ? 3 : quizzes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final quiz = quizzes[index];

            // Find the best score for this quiz
            final quizResult = results.cast<QuizResultModel?>().firstWhere(
              (r) => r?.quizId == quiz.id,
              orElse: () => null,
            );

            return _buildQuizCard(
              context: context,
              quiz: quiz,
              progress: quizResult?.percentage ?? 0.0,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        if (err.toString().contains('401')) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  const SizedBox(height: 8),
                  const Text('Session expired. Please log in again.', style: TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: () {
                      ref.read(authServiceProvider).logout();
                      ref.read(authStateProvider.notifier).state = null;
                    },
                    child: const Text('Log Out'),
                  )
                ],
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Failed to load quizzes. Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizCard({
    required BuildContext context,
    required QuizModel quiz,
    required double progress,
  }) {
    final bool isCompleted = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/classes/book_icon.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz.metaLine.isNotEmpty ? quiz.metaLine : "${quiz.questionCount} Questions • ${quiz.durationMinutes} min",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Color(0xFF4AA678), size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF4AA678) : AppColors.primaryMid,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentQuizQuestionsScreen(quiz: quiz),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey.shade100 : AppColors.primaryMid,
                foregroundColor: isCompleted ? Colors.grey.shade700 : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isCompleted ? "Retake Quiz" : "Start Learning",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
