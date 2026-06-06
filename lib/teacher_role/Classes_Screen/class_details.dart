import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/teacher_class_model.dart';
import '../../core/providers/teacher_provider.dart';
import '../../core/constants/api_constants.dart';

import 'student_attendence.dart';
import 'student_profile.dart';
import 'lessons_screen.dart';
import 'homework_screen.dart';
import 'lesson_overview_screen.dart';
import 'assign_students_screen.dart';
import 'add_class.dart';

class ClassDetailsScreen extends ConsumerStatefulWidget {
  final TeacherClassModel classData;
  const ClassDetailsScreen({Key? key, required this.classData})
    : super(key: key);

  @override
  ConsumerState<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends ConsumerState<ClassDetailsScreen> {
  late TeacherClassModel _classData;

  @override
  void initState() {
    super.initState();
    _classData = widget.classData;
  }

  @override
  Widget build(BuildContext context) {
    final classData = _classData;
    final studentsAsync = ref.watch(classStudentsProvider(classData.id));
    final lessonsAsync = ref.watch(classLessonsProvider(classData.id));
    final attendanceStatsAsync = ref.watch(
      classAttendanceStatsProvider(classData.id),
    );
    final String todayDate = DateFormat('dd-MM-yy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
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
                    const SizedBox(width: 16),
                    const Text(
                      "Class Detail",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignStudentsScreen(
                              classData: classData,
                            ),
                          ),
                        );
                        ref.invalidate(classStudentsProvider(classData.id));
                        ref.invalidate(teacherClassesProvider);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF904BBB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group_add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomeworkScreen(classId: classData.id),
                          ),
                        );
                      },

                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF904BBB),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/classes/home_book.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final updatedClass = await Navigator.push<TeacherClassModel>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddClassScreen(
                              classToEdit: classData,
                            ),
                          ),
                        );

                        if (updatedClass == null || !mounted) return;

                        setState(() {
                          _classData = updatedClass.copyWith(
                            studentCount: classData.studentCount,
                            attendance: classData.attendance,
                            performance: classData.performance,
                          );
                        });
                        ref.invalidate(teacherClassesProvider);
                        ref.invalidate(classStudentsProvider(classData.id));
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF904BBB),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/classes/calender.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subtitle ──
                    Text(
                      "Grade ${classData.grade} - ${classData.subject}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Stats Grid ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            "Students",
                            "${classData.studentCount}",
                            const Color(0xFF3F99B4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            "Date",
                            todayDate,
                            const Color(0xFFB87841),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: attendanceStatsAsync.when(
                            data: (percentage) => _buildStatBox(
                              "Attendance",
                              "$percentage%",
                              const Color(0xFF4AA678),
                            ),
                            loading: () => _buildStatBox(
                              "Attendance",
                              "...",
                              const Color(0xFF4AA678),
                            ),
                            error: (_, __) => _buildStatBox(
                              "Attendance",
                              "Error",
                              const Color(0xFF4AA678),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            "Performance",
                            classData.performance,
                            const Color(0xFFFEBD43),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Lessons Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lessons",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonsScreen(classId: classData.id),
                              ),
                            );
                          },
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF871DAD),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF871DAD),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 136,
                      child: lessonsAsync.when(
                        data: (lessons) {
                          if (lessons.isEmpty) {
                            return const Center(
                              child: Text("No lessons found."),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LessonOverviewScreen(lesson: lesson),
                                    ),
                                  );
                                },
                                child: _buildLessonCard(
                                  title: lesson['title'] ?? lesson['objective'] ?? 'No Title',
                                  description: lesson['note'] ?? 'No Description',
                                  dueDate: lesson['created_at'] != null
                                      ? "Date: ${lesson['created_at'].toString().split('T')[0]}"
                                      : "Date: TBD",
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text("Error: $err")),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Students Section ──
                    const Text(
                      "Students",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 16),

                    studentsAsync.when(
                      data: (students) {
                        if (students.isEmpty) {
                          return const Center(
                            child: Text("No students enrolled."),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final assignment = students[index];
                            final student = assignment['studentId'];
                            if (student == null) return const SizedBox();

                            return StudentCard(
                              studentData: student,
                              classData: classData,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text("Error: $err")),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard({
    required String title,
    required String description,
    required String dueDate,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dueDate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const Text(
                "View",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4AA678),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentCard extends ConsumerWidget {
  final Map<String, dynamic> studentData;
  final TeacherClassModel classData;

  const StudentCard({
    Key? key,
    required this.studentData,
    required this.classData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = studentData['_id'] ?? '';
    final attendanceStatsAsync = ref.watch(
      studentAttendanceStatsProvider('$studentId|${classData.id}'),
    );

    final name = studentData['username'] ?? studentData['name'] ?? 'Unknown';
    final avatar = studentData['avatar'];
    String? avatarUrl;
    if (avatar is Map) {
      avatarUrl = avatar['url'];
    } else if (avatar is String) {
      avatarUrl = avatar;
    }

    avatarUrl = ApiConstants.buildImageUrl(avatarUrl);

    // Handle PDF or invalid image formats in Cloudinary
    final bool isInvalidImage =
        avatarUrl != null && avatarUrl.toLowerCase().endsWith('.pdf');
    final String effectiveAvatarUrl = isInvalidImage ? '' : (avatarUrl ?? '');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentAttendanceScreen(classData: classData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4AA678),
                  borderRadius: BorderRadius.only(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF3F4F6),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: effectiveAvatarUrl.isNotEmpty
                                ? Image.network(
                                    effectiveAvatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/classes/student_image.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/classes/student_image.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Grade ${studentData['gradeLevel'] ?? classData.grade}",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4AA678,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Active",
                              style: TextStyle(
                                color: Color(0xFF4AA678),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Attendance",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    attendanceStatsAsync.when(
                                      data: (stats) => "$stats%",
                                      loading: () => "...%",
                                      error: (_, __) => "N/A",
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey.shade300,
                              width: 1,
                              thickness: 1,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Progress",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "85%",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
}
