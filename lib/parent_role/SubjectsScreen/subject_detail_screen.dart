import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/providers/chat_provider.dart';
import 'package:opalmer_education/chat/screens/chat_screen.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/subject.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/homework_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/attendance_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/lessons_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/behavior_record_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/academic_documents_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/grading_progress_screen.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final Subject subject;
  final String studentId;
  final String studentName;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  Subject get subject => widget.subject;
  String get studentId => widget.studentId;
  String get studentName => widget.studentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryMid,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Summary Row (Attendance & Progress) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      label: "Attendance",
                      value: "${subject.attendance}${subject.attendanceEmoji}",
                      color: const Color(0xFF4CB07D),
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      label: "Progress",
                      value: subject.performance,
                      color: const Color(0xFFF4B84F),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Teacher Profile ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Teacher Profile",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(subject.teacherAvatar),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        subject.teacherName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    _buildContactButton(
                      Icons.chat_bubble_rounded,
                      onTap: _openTeacherChat,
                    ),
                    const SizedBox(width: 12),
                    _buildContactButton(Icons.phone_rounded, onTap: () {}),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Progress Chart ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(),

              const SizedBox(height: 24),

              // ── Action Grid ──
              _buildActionTile(
                "Home Work",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkScreen(
                        classId: subject.id,
                        subjectName: subject.name,
                      ),
                    ),
                  );
                },
              ),
              _buildActionTile(
                "Attendance",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreen(
                        subjectName: subject.name,
                        classId: subject.id,
                        studentId: studentId,
                        studentName: studentName,
                      ),
                    ),
                  );
                },
              ),
              _buildActionTile(
                "Lessons",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonsScreen(
                        classId: subject.id,
                        subjectName: subject.name,
                      ),
                    ),
                  );
                },
              ),
              _buildActionTile(
                "Behavior Record",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BehaviorRecordScreen(
                        subjectName: subject.name,
                        childId: studentId,
                        childName: studentName,
                      ),
                    ),
                  );
                },
              ),
              _buildActionTile(
                "Academic Documents",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AcademicDocumentsScreen(
                        subjectName: subject.name,
                        childId: studentId,
                        childName: studentName,
                      ),
                    ),
                  );
                },
              ),
              _buildActionTile(
                "Grading Progress",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GradingProgressScreen(
                        subjectName: subject.name,
                        childId: studentId,
                        classId: subject.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTeacherChat() async {
    final teacherId = subject.teacherId;

    if (teacherId == null || teacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher information unavailable")),
      );
      return;
    }

    try {
      final room = await ref
          .read(chatNotifierProvider.notifier)
          .getOrCreateDirectRoom(teacherId);

      if (!mounted) return;

      if (room == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initialize chat session")),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            session: room,
            role: ChatRole.parent,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to initialize chat session")),
      );
    }
  }

  Widget _buildContactButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primaryMid,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progress",
                style: TextStyle(
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryMid.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text(
                      "Weekly",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryMid,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: AppColors.primaryMid,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          "Sun",
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                        ];
                        if (value >= 0 && value < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primaryMid,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryMid.withValues(alpha: 0.3),
                          AppColors.primaryMid.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots:
                        subject.weeklyProgress
                            ?.map((p) => FlSpot(p.x, p.y))
                            .toList() ??
                        [
                          const FlSpot(0, 20),
                          const FlSpot(2, 40),
                          const FlSpot(4, 30),
                          const FlSpot(6, 60),
                        ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
