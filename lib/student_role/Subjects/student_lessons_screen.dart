import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/student_role/Subjects/student_lesson_overview_screen.dart';

class StudentLessonsScreen extends ConsumerWidget {
  const StudentLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(studentLessonsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primaryMid,
        onRefresh: () async {
          ref.invalidate(studentLessonsProvider);
          await ref.read(studentLessonsProvider.future);
        },
        child: lessonsAsync.when(
          data: (lessons) => _buildContent(context, lessons),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildError(context, ref),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List lessons) {
    if (lessons.isEmpty) return _buildEmpty(context);

    final todayLessons = lessons.where((l) => !l.isArchived).toList();
    final archivedLessons = lessons.where((l) => l.isArchived).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todayLessons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Today's Lesson",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...todayLessons
                .map((l) => _buildLessonCard(context, lesson: l)),
          ],
          if (archivedLessons.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Archived Lessons",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primaryMid,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...archivedLessons
                .map((l) => _buildLessonCard(context, lesson: l)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        const Icon(
          Icons.menu_book_outlined,
          size: 72,
          color: AppColors.primaryMid,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No lessons yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your teacher hasn\'t posted any lessons yet. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        const Icon(Icons.error_outline,
            size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Could not load lessons right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMid,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.invalidate(studentLessonsProvider),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryMid,
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
        "Lessons",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context, {
    required LessonModel lesson,
  }) {
    final dateStr = lesson.createdAt != null 
      ? "Created: ${lesson.createdAt!.toString().split(' ')[0]}" 
      : "Open Date";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            lesson.objective,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentLessonOverviewScreen(lesson: lesson),
                    ),
                  );
                },
                child: const Text(
                  "View",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4AA678),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
