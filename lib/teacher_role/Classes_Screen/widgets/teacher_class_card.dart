import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/teacher_class_model.dart';
import '../../../core/providers/teacher_provider.dart';
import '../class_details.dart';

class TeacherClassCard extends ConsumerWidget {
  final TeacherClassModel classData;
  final Color color;
  final double? width;
  final EdgeInsetsGeometry margin;

  const TeacherClassCard({
    super.key,
    required this.classData,
    required this.color,
    this.width,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStatsAsync = ref.watch(
      classAttendanceStatsProvider(classData.id),
    );
    final section = classData.section?.trim();
    final schedule = classData.schedule?.trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassDetailsScreen(classData: classData),
          ),
        );
      },
      child: Container(
        width: width,
        margin: margin,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/classes/book_icon.png',
                      width: 23,
                      height: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData.subject.isEmpty
                            ? 'Untitled Class'
                            : classData.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          'Grade ${classData.grade}',
                          if (section != null && section.isNotEmpty)
                            'Section $section',
                        ].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.schedule,
              text: schedule == null || schedule.isEmpty
                  ? 'Schedule not set'
                  : schedule,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.people_outline,
              text:
                  '${classData.studentCount} ${classData.studentCount == 1 ? 'Student' : 'Students'}',
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Attendance',
                      value: attendanceStatsAsync.when(
                        data: (percentage) => '$percentage%',
                        loading: () => '...',
                        error: (_, __) => 'N/A',
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.65),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Performance',
                      value: classData.performance,
                    ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
