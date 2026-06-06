import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/student_role/Quizzes/student_quiz_result_screen.dart';

class StudentQuizQuestionsScreen extends ConsumerStatefulWidget {
  final QuizModel quiz;
  const StudentQuizQuestionsScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  ConsumerState<StudentQuizQuestionsScreen> createState() =>
      _StudentQuizQuestionsScreenState();
}

class _StudentQuizQuestionsScreenState
    extends ConsumerState<StudentQuizQuestionsScreen> {
  final Map<int, int> _answers = {};
  bool _isSubmitting = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      await ref.read(studentServiceProvider).startQuiz(widget.quiz.id);
    } catch (e) {
      debugPrint('Error starting quiz: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _saveAnswer(int questionIdx, int optionIdx, List<QuizQuestion> questions) async {
    setState(() => _answers[questionIdx] = optionIdx);
    
    // Auto-save progress to backend
    try {
      final question = questions[questionIdx];
      await ref.read(studentServiceProvider).saveQuizProgress(
        widget.quiz.id,
        question.question,
        question.options[optionIdx],
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _submitQuiz(List<QuizQuestion> questions) async {
    final user = ref.read(authStateProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_answers.containsKey(i)) {
          final selectedOption = questions[i].options[_answers[i]!];
          if (selectedOption == questions[i].answer) {
            score++;
          }
        }
      }

      final result = await ref.read(studentServiceProvider).submitQuiz(
        widget.quiz.id,
        user.id,
        score,
        questions.length,
      );

      if (result != null && mounted) {
        // Invalidate providers so the dashboard and other screens fetch fresh data
        ref.invalidate(studentQuizResultsProvider);
        ref.invalidate(studentClassesProvider);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentQuizResultScreen(result: result)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit quiz. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizQAAsync = ref.watch(quizQAProvider(widget.quiz.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _isInitializing 
        ? const Center(child: CircularProgressIndicator())
        : quizQAAsync.when(
            data: (quizQA) {
          if (quizQA == null || quizQA.questions.isEmpty) {
            return _buildEmptyState();
          }
          final questions = quizQA.questions;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    _buildQuizInfoCard(questions.length),
                    const SizedBox(height: 24),
                    ...questions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final q = entry.value;
                      return _buildQuestionCard(
                        idx,
                        q,
                        questions,
                      );
                    }).toList(),
                  ],
                ),
              ),
              _buildFooter(context, questions),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(err),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 72,
              color: AppColors.primaryMid,
            ),
            const SizedBox(height: 16),
            const Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your teacher hasn\'t added questions to this quiz yet. Check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(quizQAProvider(widget.quiz.id)),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final isNetwork = error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('socketexception');
    final message = isNetwork
        ? 'Could not reach the server. Please check your connection.'
        : 'Something went wrong while loading questions.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMid,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  ref.invalidate(quizQAProvider(widget.quiz.id)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryMid,
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
        "Questions",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuizInfoCard(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4AA678),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow("Quiz Name", widget.quiz.title),
          const SizedBox(height: 12),
          _buildInfoRow("Total Questions", totalQuestions.toString()),
          const SizedBox(height: 12),
          _buildInfoRow("Teacher", widget.quiz.teacherName ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, QuizQuestion question, List<QuizQuestion> questions) {
    final resolvedImageUrl = ApiConstants.buildImageUrl(question.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${index + 1}. ${question.question}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (resolvedImageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolvedImageUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: Text(
                    'Image unavailable',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...question.options.asMap().entries.map((entry) {
            int optIdx = entry.key;
            String text = entry.value;
            bool isSelected = _answers[index] == optIdx;

            return GestureDetector(
              onTap: () => _saveAnswer(index, optIdx, questions),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryMid
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryMid,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected
                              ? AppColors.primaryMid
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, List<QuizQuestion> questions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (_isSubmitting || _isInitializing) ? null : () => _submitQuiz(questions),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "COMPLETE QUIZ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
