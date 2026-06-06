import 'package:flutter/material.dart';

enum BadgeStatus { earned, inProgress, unsupported }

class StudentBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final Color progressColor;

  /// Current progress (0.0 – 1.0). Null when the badge is unsupported.
  final double? progress;

  /// Target threshold (0.0 – 1.0) that unlocks the badge.
  final double targetThreshold;

  final BadgeStatus status;

  /// Short note shown when the badge can't be computed (missing backend).
  final String? unsupportedReason;

  const StudentBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.progressColor,
    required this.progress,
    required this.targetThreshold,
    required this.status,
    this.unsupportedReason,
  });

  bool get isEarned => status == BadgeStatus.earned;
  bool get isUnsupported => status == BadgeStatus.unsupported;

  /// Percentage label shown at the progress-bar start (current progress).
  String get progressLabel =>
      progress == null ? '—' : '${(progress! * 100).round()}%';

  /// Percentage label shown at the progress-bar end (target threshold).
  String get targetLabel => '${(targetThreshold * 100).round()}%';
}
