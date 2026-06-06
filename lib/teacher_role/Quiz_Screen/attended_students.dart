import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/grading_provider.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/student_detail.dart';

class AttendedStudentsScreen extends ConsumerWidget {
  final String sessionId;
  const AttendedStudentsScreen({super.key, required this.sessionId});

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(
      attendedSubmittedStudentsProvider(sessionId),
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
          "Attended Students",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (data) {
          final List<dynamic> attended = data['results'] ?? [];
          final List<dynamic> notAttended = data['notAttendedStudents'] ?? [];

          // Merge both lists into a single normalized list
          final List<Map<String, dynamic>> allStudents = [
            ...attended.map(
              (r) => {
                'student': r['studentId'],
                'progress': _toNum(r['totalQuestions']) > 0
                    ? (_toNum(r['score']) / _toNum(r['totalQuestions']))
                          .clamp(0, 1)
                          .toDouble()
                    : 0.0,
                'isAttended': true,
              },
            ),
            ...notAttended.map(
              (s) => {'student': s, 'progress': 0.0, 'isAttended': false},
            ),
          ];

          if (allStudents.isEmpty) {
            return const Center(
              child: Text("No students found for this class"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: allStudents.length,
            itemBuilder: (context, index) {
              final item = allStudents[index];
              final student = item['student'];
              final name = student != null
                  ? student['username'] ?? 'Unknown'
                  : 'Unknown';
              final grade = student != null
                  ? student['gradeLevel'] ?? student['grade'] ?? 'N/A'
                  : 'N/A';
              final progress = item['progress'] as double;

              // Use backend avatar URL if available, else fallback to asset
              String imageUrl = 'assets/images/classes/student_image.png';
              final avatar = student?['avatar'];
              if (avatar != null) {
                if (avatar is Map &&
                    avatar['url'] != null &&
                    avatar['url'].toString().isNotEmpty) {
                  imageUrl = avatar['url'].toString();
                } else if (avatar is String && avatar.isNotEmpty) {
                  imageUrl = avatar;
                }
              }

              // Cycle through colors: Green, Orange, Blue
              final colors = [
                const Color(0xFF4DB68D),
                const Color(0xFFFFCC33),
                const Color(0xFF4FA0F3),
              ];
              final sideColor = colors[index % colors.length];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentDetailScreen(),
                    ),
                  );
                },
                child: _buildStudentCard(
                  name: name,
                  details: "Grade $grade",
                  progress: progress,
                  sideColor: sideColor,
                  imageUrl: imageUrl,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String details,
    required double progress,
    required Color sideColor,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Side Colored Border
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: imageUrl.startsWith('http')
                              ? NetworkImage(imageUrl) as ImageProvider
                              : AssetImage(imageUrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                details,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar Section
                    Row(
                      children: [
                        const Text(
                          "0%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF871DAD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF1F0F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF871DAD),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
