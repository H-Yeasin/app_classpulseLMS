import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/badge_model.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';

/// Aggregates quiz, attendance, and behavior data into a list of badges with
/// real progress values. Badges that have no backend data source are emitted
/// with [BadgeStatus.unsupported] so the UI can either hide them or flag
/// them — no hardcoded percentages leak into the screen.
final studentBadgesProvider = FutureProvider<List<StudentBadge>>((ref) async {
  final quizResults =
      await ref.watch(studentQuizResultsProvider.future);
  final attendance =
      await ref.watch(studentAttendanceProvider.future);
  final behaviors =
      await ref.watch(studentBehaviorsProvider.future);

  return [
    _starStudent(quizResults),
    _perfectAttendance(attendance),
    _participationPro(),
    _roleModel(behaviors),
  ];
});

StudentBadge _starStudent(List<QuizResultModel> results) {
  const target = 0.9;
  if (results.isEmpty) {
    return const StudentBadge(
      id: 'star_student',
      emoji: '⭐',
      title: 'Star Student',
      description:
          'Consistently striving for excellence in every subject. Your dedication shines bright every day!',
      progressColor: Color(0xFFF04F4F),
      progress: 0,
      targetThreshold: target,
      status: BadgeStatus.inProgress,
    );
  }
  final avg = results.fold<double>(0, (sum, r) => sum + r.percentage) /
      results.length;
  return StudentBadge(
    id: 'star_student',
    emoji: '⭐',
    title: 'Star Student',
    description:
        'Consistently striving for excellence in every subject. Your dedication shines bright every day!',
    progressColor: const Color(0xFFF04F4F),
    progress: avg.clamp(0, 1),
    targetThreshold: target,
    status:
        avg >= target ? BadgeStatus.earned : BadgeStatus.inProgress,
  );
}

StudentBadge _perfectAttendance(List<AttendanceRecord> records) {
  const target = 1.0;
  final counted =
      records.where((r) => !r.isHoliday).toList(growable: false);
  if (counted.isEmpty) {
    return const StudentBadge(
      id: 'perfect_attendance',
      emoji: '🎯',
      title: 'Perfect Attendance',
      description:
          '100% attendance and 100% dedication. Consistency is your superpower!',
      progressColor: Color(0xFFF9A825),
      progress: 0,
      targetThreshold: target,
      status: BadgeStatus.inProgress,
    );
  }
  final present = counted.where((r) => r.isPresent).length;
  final ratio = present / counted.length;
  return StudentBadge(
    id: 'perfect_attendance',
    emoji: '🎯',
    title: 'Perfect Attendance',
    description:
        '100% attendance and 100% dedication. Consistency is your superpower!',
    progressColor: const Color(0xFFF9A825),
    progress: ratio,
    targetThreshold: target,
    status:
        ratio >= target ? BadgeStatus.earned : BadgeStatus.inProgress,
  );
}

StudentBadge _participationPro() {
  // No backend source for participation events yet; surface as unsupported so
  // the UI can indicate "coming soon" instead of faking a number.
  return const StudentBadge(
    id: 'participation_pro',
    emoji: '🗣️',
    title: 'Participation Pro',
    description:
        'Never afraid to raise your hand or help others. Your involvement lifts the whole classroom!',
    progressColor: Color(0xFF4CAF50),
    progress: null,
    targetThreshold: 0.9,
    status: BadgeStatus.unsupported,
    unsupportedReason:
        'Participation tracking is not available yet. Ask your teacher for updates.',
  );
}

StudentBadge _roleModel(List<BehaviorRecord> behaviors) {
  const target = 0.9;
  if (behaviors.isEmpty) {
    return const StudentBadge(
      id: 'role_model',
      emoji: '👏',
      title: 'Role Model Behavior',
      description:
          'Your actions speak louder than words. Thank you for making our classroom a better place!',
      progressColor: Color(0xFFFFB300),
      progress: 0,
      targetThreshold: target,
      status: BadgeStatus.inProgress,
    );
  }
  final positive = behaviors.where((b) => b.isPositive).length;
  final ratio = positive / behaviors.length;
  return StudentBadge(
    id: 'role_model',
    emoji: '👏',
    title: 'Role Model Behavior',
    description:
        'Your actions speak louder than words. Thank you for making our classroom a better place!',
    progressColor: const Color(0xFFFFB300),
    progress: ratio,
    targetThreshold: target,
    status:
        ratio >= target ? BadgeStatus.earned : BadgeStatus.inProgress,
  );
}
