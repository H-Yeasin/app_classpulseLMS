import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opalmer_education/student_role/Subjects/student_homework_screen.dart';
import 'package:opalmer_education/student_role/Subjects/student_attendance_screen.dart';
import 'package:opalmer_education/student_role/Subjects/student_lessons_screen.dart';
import 'package:opalmer_education/student_role/Subjects/student_academic_notes_screen.dart';
import 'package:opalmer_education/student_role/Subjects/student_grading_progress_screen.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';
import 'package:opalmer_education/chat/providers/chat_provider.dart';
import 'package:opalmer_education/chat/screens/chat_screen.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/screens/call.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectName;
  final LessonModel? lesson;
  final StudentClassModel? studentClass;

  const SubjectDetailScreen({
    Key? key,
    this.subjectName = "Science",
    this.lesson,
    this.studentClass,
  }) : super(key: key);

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  String _filterPeriod = "Weekly";

  @override
  Widget build(BuildContext context) {
    final classId = widget.studentClass?.id ?? widget.lesson?.classId;

    final attendanceAsync = classId != null
        ? ref.watch(studentClassAttendanceProvider(classId))
        : const AsyncData(<AttendanceRecord>[]);

    final quizResultsAsync = classId != null
        ? ref.watch(studentClassQuizResultsProvider(classId))
        : const AsyncData(<QuizResultModel>[]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildStatCards(attendanceAsync, quizResultsAsync),
            const SizedBox(height: 32),
            const Text(
              "Teacher Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTeacherProfile(),
            const SizedBox(height: 32),
            _buildProgressSection(quizResultsAsync),
            const SizedBox(height: 32),
            _buildOptionsList(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(
    AsyncValue<List<AttendanceRecord>> attendanceAsync,
    AsyncValue<List<QuizResultModel>> quizResultsAsync,
  ) {
    final String attendanceVal = attendanceAsync.maybeWhen(
      data: (records) {
        if (records.isEmpty) {
          return widget.studentClass?.attendancePercentage != null
              ? "${widget.studentClass!.attendancePercentage}%"
              : "0%";
        }
        // Match backend logic: Filter out holidays
        final relevantRecords = records.where((r) => r.status.toLowerCase() != "holiday").toList();
        if (relevantRecords.isEmpty) return "0%";
        
        final presentCount =
            relevantRecords.where((r) => r.status.toLowerCase() == "present").length;
        return "${((presentCount / relevantRecords.length) * 100).toInt()}%";
      },
      loading: () => widget.studentClass?.attendancePercentage != null
          ? "${widget.studentClass!.attendancePercentage}%"
          : "...",
      orElse: () => widget.studentClass?.attendancePercentage != null
          ? "${widget.studentClass!.attendancePercentage}%"
          : "0%",
    );

    final String progressVal = quizResultsAsync.maybeWhen(
      data: (results) {
        if (results.isEmpty) {
          return widget.studentClass?.performancePercentage != null
              ? "${widget.studentClass!.performancePercentage}%"
              : "0%";
        }
        final avg =
            results.fold<double>(0, (sum, res) => sum + res.percentage) /
            results.length;
        return "${(avg * 100).toInt()}%";
      },
      loading: () => widget.studentClass?.performancePercentage != null
          ? "${widget.studentClass!.performancePercentage}%"
          : "...",
      orElse: () => widget.studentClass?.performancePercentage != null
          ? "${widget.studentClass!.performancePercentage}%"
          : "0%",
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: "Attendance",
            value: attendanceVal,
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF4AA678),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            label: "Performance",
            value: progressVal,
            icon: Icons.insights_rounded,
            color: const Color(0xFFFEBD43),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherProfile() {
    final teacherName =
        widget.studentClass?.teacherName ?? widget.lesson?.teacher?.username;
    final teacherAvatar =
        widget.studentClass?.teacherAvatar ?? widget.lesson?.teacher?.avatar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryMid.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryMid.withValues(alpha: 0.1),
              backgroundImage: teacherAvatar != null && teacherAvatar.isNotEmpty
                  ? NetworkImage(teacherAvatar) as ImageProvider
                  : null,
              child: teacherAvatar == null || teacherAvatar.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primaryMid)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName ?? "No Teacher Assigned",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Subject Instructor",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildCircleActionIcon(Icons.chat_bubble_rounded, () async {
                final teacherId = widget.studentClass?.teacherId ?? widget.lesson?.teacherId;
                if (teacherId != null) {
                  final room = await ref.read(chatNotifierProvider.notifier).getOrCreateDirectRoom(teacherId);
                  if (room != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          session: room,
                          role: ChatRole.student,
                        ),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to initialize chat session")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Teacher information unavailable")),
                  );
                }
              }),
              const SizedBox(width: 12),
              _buildCircleActionIcon(Icons.phone_outlined, () {
                if (teacherName != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        name: teacherName,
                        imageUrl: teacherAvatar ?? "",
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryMid, size: 18),
      ),
    );
  }

  Widget _buildProgressSection(
    AsyncValue<List<QuizResultModel>> quizResultsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterPeriod = _filterPeriod == "Weekly"
                      ? "Monthly"
                      : "Weekly";
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryMid),
                ),
                child: Row(
                  children: [
                    Text(
                      _filterPeriod,
                      style: const TextStyle(
                        color: AppColors.primaryMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryMid,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: quizResultsAsync.when(
            data: (results) {
              List<FlSpot> spots = [];
              double maxX = 6;
              final now = DateTime.now();

              // Check if we should use individual results or pre-calculated weekly progress
              if (results.isEmpty &&
                  widget.studentClass?.weeklyProgress != null &&
                  widget.studentClass!.weeklyProgress.isNotEmpty) {
                maxX = 6;
                final wp = widget.studentClass!.weeklyProgress;
                const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                for (int i = 0; i < 7; i++) {
                  final label = days[i];
                  final progress = wp.firstWhere(
                    (p) => p.dayLabel.startsWith(label),
                    orElse: () =>
                        WeeklyProgress(dayLabel: label, percentage: 0),
                  );
                  spots.add(
                    FlSpot(i.toDouble(), (progress.percentage ?? 0).toDouble()),
                  );
                }
              } else if (_filterPeriod == "Weekly") {
                maxX = 6;
                Map<int, List<double>> dayScores = {};
                for (var res in results) {
                  if (res.createdAt != null) {
                    final diff = now.difference(res.createdAt!).inDays;
                    if (diff <= 7) {
                      int weekday = res.createdAt!.weekday % 7; // Sun=0
                      dayScores
                          .putIfAbsent(weekday, () => [])
                          .add(res.percentage * 100);
                    }
                  }
                }
                for (int i = 0; i <= 6; i++) {
                  final scores = dayScores[i];
                  double val = scores == null || scores.isEmpty
                      ? 0
                      : scores.reduce((a, b) => a + b) / scores.length;
                  spots.add(FlSpot(i.toDouble(), val));
                }
              } else {
                // Monthly view: last 30 days grouped into 4-5 weeks
                maxX = 4;
                Map<int, List<double>> weekScores = {};
                for (var res in results) {
                  if (res.createdAt != null) {
                    final diff = now.difference(res.createdAt!).inDays;
                    if (diff <= 30) {
                      int weekIndex = (diff / 7).floor();
                      if (weekIndex > 4) weekIndex = 4;
                      weekScores
                          .putIfAbsent(4 - weekIndex, () => [])
                          .add(res.percentage * 100);
                    }
                  }
                }
                for (int i = 0; i <= 4; i++) {
                  final scores = weekScores[i];
                  double val = scores == null || scores.isEmpty
                      ? 0
                      : scores.reduce((a, b) => a + b) / scores.length;
                  spots.add(FlSpot(i.toDouble(), val));
                }
              }

              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (_filterPeriod == "Weekly") {
                            const days = [
                              'Sun',
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                            ];
                            if (value >= 0 && value < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                          } else {
                            const weeks = ['W1', 'W2', 'W3', 'W4', 'W5'];
                            if (value >= 0 && value < weeks.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  weeks[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaryMid,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryMid.withValues(alpha: 0.35),
                            AppColors.primaryMid.withValues(alpha: 0.01),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        widget.subjectName,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryMid.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryMid,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(BuildContext context) {
    final options = [
      {
        "title": "Home Work",
        "icon": Icons.home_work_rounded,
        "color": const Color(0xFF6C5CE7),
      },
      {
        "title": "Attendance",
        "icon": Icons.calendar_month_rounded,
        "color": const Color(0xFF00B894),
      },
      {
        "title": "Lessons",
        "icon": Icons.auto_stories_rounded,
        "color": const Color(0xFF0984E3),
      },
      {
        "title": "Academic Notes",
        "icon": Icons.description_rounded,
        "color": const Color(0xFFE17055),
      },
      {
        "title": "Grading Progress",
        "icon": Icons.analytics_rounded,
        "color": const Color(0xFFD63031),
      },
    ];

    return Column(
      children: options
          .map(
            (opt) => _buildOptionTile(
              context,
              opt["title"] as String,
              opt["icon"] as IconData,
              opt["color"] as Color,
            ),
          )
          .toList(),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 24,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          if (title == "Home Work") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeworkScreen(),
              ),
            );
          } else if (title == "Attendance") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentAttendanceScreen(),
              ),
            );
          } else if (title == "Lessons") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentLessonsScreen(),
              ),
            );
          } else if (title == "Academic Notes") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentAcademicNotesScreen(),
              ),
            );
          } else if (title == "Grading Progress") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentGradingProgressScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}
