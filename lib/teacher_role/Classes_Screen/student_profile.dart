import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/providers/chat_provider.dart';
import '../../core/providers/teacher_provider.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/screens/call.dart';
import 'package:opalmer_education/chat/screens/chat_screen.dart';
import 'package:opalmer_education/chat/services/chat_api_service.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

import 'behavior_record.dart';
import 'academic_documents.dart';
import 'grading_progress.dart';


class StudentProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> studentData;
  final String? classId;

  const StudentProfileScreen({
    Key? key,
    required this.studentData,
    this.classId,
  }) : super(key: key);

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  String _selectedFilter = 'weekly';

  Color _getAttendanceColor(int percentage) {
    if (percentage >= 90) return const Color(0xFF4AA678); // Green
    if (percentage >= 80) return const Color(0xFF3F99B4); // Blue
    if (percentage >= 70) return const Color(0xFFFEBD43); // Yellow
    return const Color(0xFFC04345); // Red
  }

  String _getAttendanceEmoji(int percentage) {
    if (percentage >= 90) return "😋";
    if (percentage >= 80) return "😐";
    if (percentage >= 70) return "😋"; // Using same for now, or 🤑
    return "😡";
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.studentData;
    final studentId = student['_id'] ?? '';
    final classId = widget.classId ?? '';
    final attendanceStatsAsync = ref.watch(
      studentAttendanceStatsProvider('$studentId|$classId'),
    );
    final parentsAsync = ref.watch(studentParentsProvider(studentId));
    final quizResultsAsync = ref.watch(studentQuizResultsProvider(studentId));

    final analysisAsync = ref.watch(
      studentAnalysisProvider('$classId|$studentId|$_selectedFilter'),
    );

    // Use percentage from analysis summary
    final progressPercentStr = analysisAsync.maybeWhen(
      data: (data) {
        if (data.isNotEmpty && data['summary'] != null) {
          final percentage = data['summary']['percentage']?.toString() ?? "0";
          if (percentage.contains('.')) {
            return double.parse(percentage).round().toString();
          }
          return percentage;
        }
        return "0";
      },
      orElse: () => "0",
    );

    // Debug print to see what data we are getting
    debugPrint('StudentProfile: Analysis State: ${analysisAsync.isLoading ? "Loading" : "Loaded"}');
    if (analysisAsync.hasValue) {
      debugPrint('StudentProfile: Analysis Data: ${analysisAsync.value}');
    }

    // Handle avatar
    final avatar = student['avatar'];
    String? avatarUrl;
    if (avatar is Map) {
      avatarUrl = avatar['url'];
    } else if (avatar is String) {
      avatarUrl = avatar;
    }

    // Fix relative URL using ApiConstants
    avatarUrl = ApiConstants.buildImageUrl(avatarUrl);

    // Handle PDF or invalid image formats in Cloudinary
    if (avatarUrl != null && avatarUrl.toLowerCase().endsWith('.pdf')) {
      avatarUrl = null;
    }

    // Fallback image if avatarUrl is empty
    if (avatarUrl == null || avatarUrl.isEmpty) {
      avatarUrl = null;
    }

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
                  vertical: 12,
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
                      "Student Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                    // ── Student Info Block ──
                    Row(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF3F4F6),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: avatarUrl != null
                              ? Image.network(
                                  avatarUrl,
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['username'] ??
                                    student['name'] ??
                                    'Unknown Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Grade ${student['gradeLevel'] ?? student['grade'] ?? student['grade_level'] ?? 'N/A'} - Age ${student['age'] ?? 'N/A'}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student['phoneNumber'] ??
                                    student['phone'] ??
                                    '01700000000',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildAction(
                          Icons.chat_bubble_outline,
                          onTap: () => _handleChat(
                            studentId,
                            student['username'] ?? 'Student',
                            avatarUrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildAction(
                          Icons.phone_outlined,
                          onTap: () => _handleCall(
                            student['username'] ?? 'Student',
                            avatarUrl ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Stats Block ──
                    Row(
                      children: [
                        Expanded(
                          child: attendanceStatsAsync.when(
                            data: (percentage) => _buildStatBox(
                              "Attendance",
                              "$percentage%${_getAttendanceEmoji(percentage)}",
                              _getAttendanceColor(percentage),
                            ),
                            loading: () => _buildStatBox(
                              "Attendance",
                              "...%",
                              const Color(0xFF4AA678),
                            ),
                            error: (_, __) => _buildStatBox(
                              "Attendance",
                              "N/A",
                              const Color(0xFFC04345),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            "Progress",
                            "$progressPercentStr%",
                            const Color(0xFFFEBD43),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Parent Profile Block ──
                    const Text(
                      "Parent Profile",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 16),
                    parentsAsync.when(
                      data: (parents) {
                        if (parents.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 28),
                            child: Text(
                              "No parent linked",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        // For now, show the first parent
                        final parentRelation = parents[0];
                        final parentUser = parentRelation['parentId'];
                        if (parentUser == null) return const SizedBox();

                        final parentName = parentUser['username'] ?? 'Parent';
                        final avatarData = parentUser['avatar'];
                        final String? avatarUrl = ApiConstants.buildImageUrl(
                          (avatarData is Map)
                              ? avatarData['url']
                              : (avatarData is String ? avatarData : null),
                        );

                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF871DAD),
                                      width: 1.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child:
                                      avatarUrl != null && avatarUrl.isNotEmpty
                                      ? Image.network(
                                          avatarUrl,
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    parentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                                _buildAction(
                                  Icons.chat_bubble_outline,
                                  onTap: () => _handleChat(
                                    parentUser['_id'],
                                    parentName,
                                    avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildAction(
                                  Icons.phone_outlined,
                                  onTap: () =>
                                      _handleCall(parentName, avatarUrl ?? ''),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Error: $err"),
                      ),
                    ),

                    // ── Progress Chart ──
                    const Text(
                      "Progress",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Progress",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF871DAD),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = _selectedFilter == 'weekly' ? 'monthly' : 'weekly';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF871DAD),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedFilter == 'weekly' ? "Weekly" : "Monthly",
                                        style: const TextStyle(
                                          color: Color(0xFF871DAD),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFF871DAD),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: analysisAsync.when(
                              data: (data) {
                                if (data.isEmpty || data['chartData'] == null) {
                                  return const Center(child: Text("No data available"));
                                }
                                final List<dynamic> chartData = data['chartData'];
                                final labels = chartData.map((e) => (e['label'] as String).substring(0, 3)).toList();
                                final values = chartData.map((e) {
                                  final p = e['present'] as int;
                                  final a = e['absent'] as int;
                                  if (p + a == 0) return 0.0;
                                  return (p / (p + a)) * 100.0;
                                }).toList();

                                return CustomPaint(
                                  painter: _ProgressChartPainter(
                                    labels: labels,
                                    values: values,
                                  ),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, _) => Center(child: Text("Error: $err")),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── List Items ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BehaviorRecordScreen(
                              studentId: studentId,
                              student: student,
                            ),
                          ),
                        );
                      },
                      child: _buildListTile("Behavior Record"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AcademicDocumentsScreen(studentId: studentId),
                          ),
                        );
                      },
                      child: _buildListTile("Academic Notes"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GradingProgressScreen(),
                          ),
                        );
                      },
                      child: _buildListTile("Grading Progress"),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF871DAD),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Future<void> _handleChat(
    String otherUserId,
    String name,
    String? avatar,
  ) async {
    final user = ref.read(authStateProvider);
    if (user == null) return;

    final chatApi = ChatApiService();
    // Create or get room
    final room = await chatApi.createRoom([otherUserId], user.id);
    if (room != null && mounted) {
      // Register room with notifier to ensure socket join and local list update
      ref.read(chatNotifierProvider.notifier).addRoom(room);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(session: room, role: ChatRole.teacher),
        ),
      );
    }
  }

  void _handleCall(String name, String avatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(name: name, imageUrl: avatar),
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

  Widget _buildListTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;

  _ProgressChartPainter({required this.labels, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double topMargin = 30.0;
    final double botMargin = 30.0;
    final double leftMargin = 30.0;
    final double rightMargin = 10.0;

    final double chartW = w - leftMargin - rightMargin;
    final double chartH = h - topMargin - botMargin;

    // Grid labels mappings
    final List<int> yLabels = [100, 50, 40, 30, 20, 10];
    final int hLines = 6;
    final double yStep = chartH / (hLines - 1);

    // Draw Grid and Text
    final TextPainter textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < hLines; i++) {
      final double y = topMargin + (i * yStep);

      // Grid line
      final Paint gridPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Dashed line manual draw
      double startX = leftMargin;
      while (startX < w) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 4, y), gridPaint);
        startX += 8;
      }

      // Label text
      textPainter.text = TextSpan(
        text: yLabels[i].toString(),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // X Labels
    final List<String> xLabels = labels;
    final double xStep = chartW / (xLabels.length - 1);

    for (int i = 0; i < xLabels.length; i++) {
      final double x = leftMargin + (i * xStep);
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topMargin + chartH + 10),
      );
    }

    // Data mapped onto non-linear Y axis where each segment is logically one fifth
    double mapY(double val) {
      double pos;
      if (val <= 50) {
        pos = (val) / 12.5; // Scale 0-50 to 0-4 segments
      } else {
        pos = 4 + (val - 50) / 50.0; // 4 to 5
      }
      // pos 0 is at bottom (yLabels[5]=10? No, yLabels[5] is 10, but bottom line is yLabels[5])
      // Actually let's simplify mapY to be linear for now as the yLabels are a bit weird
      return (topMargin + chartH) - (val / 100.0 * chartH);
    }

    // Foreground values (Purple Line)
    final List<double> fgVals = values;
    // Background values (Light Gray Line) - Using a dummy baseline or smoothed version
    final List<double> bgVals = values.map((v) => v * 0.7).toList();

    List<Offset> fgPoints = [];
    List<Offset> bgPoints = [];

    for (int i = 0; i < xLabels.length; i++) {
      final double x = leftMargin + (i * xStep);
      fgPoints.add(Offset(x, mapY(fgVals[i])));
      bgPoints.add(Offset(x, mapY(bgVals[i])));
    }

    Path constructSpline(List<Offset> pts) {
      Path path = Path();
      if (pts.isEmpty) return path;
      path.moveTo(pts.first.dx, pts.first.dy);
      if (pts.length < 2) return path;

      for (int i = 0; i < pts.length - 1; i++) {
        final p1 = pts[i];
        final p2 = pts[i + 1];
        
        // Simple cubic bezier for smoothness
        final double controlPointX = (p1.dx + p2.dx) / 2;
        path.cubicTo(controlPointX, p1.dy, controlPointX, p2.dy, p2.dx, p2.dy);
      }
      return path;
    }

    // 1) Draw Background Path
    final Path bgPath = constructSpline(bgPoints);
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFD1C4E9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bgPath, bgPaint);

    // 2) Draw Foreground Gradient Fill
    final Path fgPath = constructSpline(fgPoints);
    final Path fgFillPath = Path.from(fgPath);
    fgFillPath.lineTo(fgPoints.last.dx, topMargin + chartH);
    fgFillPath.lineTo(fgPoints.first.dx, topMargin + chartH);
    fgFillPath.close();

    final Paint fgFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topMargin),
        Offset(0, topMargin + chartH),
        [
          const Color(0xFF8E24AA).withValues(alpha: 0.3),
          const Color(0xFF8E24AA).withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fgFillPath, fgFillPaint);

    // 3) Draw Foreground Path
    final Paint fgPaint = Paint()
      ..color = const Color(0xFF8E24AA)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(fgPath, fgPaint);

    // 4) Draw Peak Highlight (highest value)
    int peakIndex = 0;
    double maxVal = -1.0;
    for (int i = 0; i < fgVals.length; i++) {
      if (fgVals[i] > maxVal) {
        maxVal = fgVals[i];
        peakIndex = i;
      }
    }
    
    final Offset peak = fgPoints[peakIndex];

    // Orange vertical line
    final Paint peakLinePaint = Paint()
      ..color = const Color(0xFFFFA726)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(peak.dx, peak.dy),
      Offset(peak.dx, topMargin + chartH),
      peakLinePaint,
    );

    // Circle at peak
    final Paint peakCircleBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint peakCircleBorderPaint = Paint()
      ..color = const Color(0xFFFFA726)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(peak, 5, peakCircleBgPaint);
    canvas.drawCircle(peak, 5, peakCircleBorderPaint);

    // Map label above peak
    final String peakLabel = "${maxVal.round()}%";
    textPainter.text = TextSpan(
      text: peakLabel,
      style: const TextStyle(
        color: Color(0xFF222222),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    final RRect bubbleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(peak.dx, peak.dy - 20),
        width: textPainter.width + 16,
        height: textPainter.height + 12,
      ),
      const Radius.circular(8),
    );

    // Draw shadow bubble
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(bubbleRRect, shadowPaint);

    final Paint bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bubbleRRect, bubblePaint);

    textPainter.paint(
      canvas,
      Offset(
        peak.dx - textPainter.width / 2,
        peak.dy - 20 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.values != values;
  }
}
