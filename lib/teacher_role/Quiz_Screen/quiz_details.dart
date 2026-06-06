import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/providers/grading_provider.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/attended_students.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/edit_quiz.dart';

class QuizDetailScreen extends ConsumerWidget {
  final String sessionId;
  const QuizDetailScreen({super.key, required this.sessionId});

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _extractAttendedCount(Map<String, dynamic> payload) {
    final summary = payload['summary'];
    if (summary is Map<String, dynamic>) {
      final fromSummary = summary['attendedStudents'];
      if (fromSummary != null) {
        return _toInt(fromSummary);
      }
    }

    final results = payload['results'];
    if (results is List) {
      return results.where((result) {
        if (result is! Map) return false;
        final status = result['status']?.toString().toLowerCase();
        return status == 'completed';
      }).length;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailsProvider(sessionId));
    final questionsAsync = ref.watch(sessionQuestionsProvider(sessionId));
    final attendedStudentsAsync = ref.watch(
      attendedSubmittedStudentsProvider(sessionId),
    );

    final attendedLabel = attendedStudentsAsync.when(
      data: (payload) =>
          '(${_extractAttendedCount(payload)}) STUDENTS ATTENDED',
      loading: () => '(0) STUDENTS ATTENDED',
      error: (_, stackTrace) => '(0) STUDENTS ATTENDED',
    );

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
          "Quiz Detail",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditQuizScreen(sessionId: sessionId),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(sessionDetailsProvider(sessionId));
                    ref.invalidate(sessionQuestionsProvider(sessionId));
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF871DAD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          final title = session['title'] ?? 'Untitled';
          final questionCount = session['questionCount'] ?? 0;
          final time = session['time'] ?? 0;
          final status = session['status'] ?? 'Draft';

          final classInfo = session['classId'];
          final grade = (classInfo is Map)
              ? classInfo['grade'] ?? 'N/A'
              : 'N/A';
          final subject = (classInfo is Map)
              ? classInfo['subject'] ?? 'N/A'
              : 'N/A';

          String imageUrl =
              "https://img.freepik.com/free-photo/view-planet-earth-from-space_23-2148705432.jpg";
          if (session['image'] != null &&
              session['image'].toString().isNotEmpty) {
            imageUrl = session['image'].toString();
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // Summary Green Card
                  _buildSummaryCard(
                    title,
                    questionCount,
                    time,
                    status,
                    imageUrl,
                  ),

                  const SizedBox(height: 24),
                  _buildInfoRow("Grade :", grade.toString()),
                  const SizedBox(height: 12),
                  _buildInfoRow("Subject :", subject.toString()),

                  const SizedBox(height: 28),
                  const Text(
                    "Questions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 16),

                  questionsAsync.when(
                    data: (questions) => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return _buildQuestionTile(
                          number: index + 1,
                          question: q['question'] ?? '',
                          options: List<String>.from(q['options'] ?? []),
                          answer: q['answer'] ?? '',
                          explanation: q['explanation']?.toString() ?? '',
                          type: q['type']?.toString() ?? 'normal',
                          difficulty: q['difficulty']?.toString() ?? 'medium',
                          imageUrl: q['imageUrl']?.toString() ?? '',
                          initiallyExpanded: index == 0,
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) {
                      // Check if it's a 404 (No questions found)
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No questions found for this session.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => ref.refresh(
                                sessionQuestionsProvider(sessionId),
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Fixed Bottom Button
              Positioned(
                bottom: 12,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AttendedStudentsScreen(sessionId: sessionId),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF871DAD),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF871DAD).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      attendedLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int questions,
    int time,
    String status,
    String imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4DB68D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB68D).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$questions Questions · $time min",
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTile({
    required int number,
    required String question,
    required List<String> options,
    required String answer,
    String explanation = '',
    String type = 'normal',
    String difficulty = 'medium',
    String imageUrl = '',
    bool initiallyExpanded = false,
  }) {
    final resolvedImageUrl = ApiConstants.buildImageUrl(imageUrl);

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
          iconColor: const Color(0xFF333333),
          collapsedIconColor: const Color(0xFF333333),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuestionChip(type),
                        _buildQuestionChip(difficulty),
                      ],
                    ),
                    if (resolvedImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          resolvedImageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            alignment: Alignment.center,
                            color: Colors.grey.shade100,
                            child: Text(
                              'Image preview unavailable',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...List.generate(options.length, (i) {
                    final char = String.fromCharCode(65 + i); // A, B, C, D
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
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Answer: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          answer,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionChip(String label) {
    final normalizedLabel = label.trim().isEmpty ? 'normal' : label.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF871DAD).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalizedLabel.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF871DAD),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
