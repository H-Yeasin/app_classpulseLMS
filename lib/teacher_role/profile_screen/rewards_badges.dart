import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/badge_model.dart';
import 'package:opalmer_education/core/providers/badges_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class RewardsBadgesScreen extends ConsumerWidget {
  const RewardsBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(studentBadgesProvider);

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
              child:
                  const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          "Rewards/Badges",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryMid,
        onRefresh: () async {
          ref.invalidate(studentBadgesProvider);
          await ref.read(studentBadgesProvider.future);
        },
        child: badgesAsync.when(
          data: (badges) => _buildList(badges),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildError(context, ref, err),
        ),
      ),
    );
  }

  Widget _buildList(List<StudentBadge> badges) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Earn badges for your performance, behavior, attendance, and participation!",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ...badges.map(_BadgeItem.new),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.error_outline,
            size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Could not load your badges right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMid,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.invalidate(studentBadgesProvider),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final StudentBadge badge;
  const _BadgeItem(this.badge);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badge.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  badge.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(badge: badge),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (badge.isUnsupported)
            _UnsupportedNote(reason: badge.unsupportedReason)
          else
            _ProgressBar(badge: badge),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final StudentBadge badge;
  const _StatusChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (badge.status) {
      case BadgeStatus.earned:
        bg = const Color(0xFFD4E1C6);
        fg = const Color(0xFF5B8B4D);
        label = 'Earned';
        break;
      case BadgeStatus.inProgress:
        bg = const Color(0xFFFFC6D3);
        fg = const Color(0xFFD34F70);
        label = 'Not Earned';
        break;
      case BadgeStatus.unsupported:
        bg = const Color(0xFFE0E0E0);
        fg = const Color(0xFF666666);
        label = 'Coming Soon';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _UnsupportedNote extends StatelessWidget {
  final String? reason;
  const _UnsupportedNote({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF666666)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason ?? 'Not available yet.',
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final StudentBadge badge;
  const _ProgressBar({required this.badge});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double tickRatio = badge.targetThreshold.clamp(0.0, 1.0);
        final double progressRatio =
            (badge.progress ?? 0).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Text(
                  badge.progressLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: badge.progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Positioned(
                  left: (width * tickRatio - 18)
                      .clamp(0.0, width - 36),
                  child: Text(
                    badge.targetLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: badge.progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: width * progressRatio,
                  decoration: BoxDecoration(
                    color: badge.progressColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  left: width * tickRatio,
                  top: -4,
                  child: Container(
                    width: 3,
                    height: 12,
                    color: AppColors.primaryMid,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
