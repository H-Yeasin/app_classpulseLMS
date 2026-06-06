import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/lesson_overview_screen.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/lesson.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  final String classId;
  final String subjectName;

  const LessonsScreen({
    super.key,
    required this.classId,
    required this.subjectName,
  });

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  final ApiClient _api = ApiClient();

  List<Lesson> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(
        ApiConstants.lessonsByClass(widget.classId),
      );
      final rawLessons = (response.data is Map && response.data['data'] is List)
          ? (response.data['data'] as List)
          : const [];

      final lessons = rawLessons
          .map(
            (json) => Lesson.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _lessons = lessons;
      });
    } catch (e) {
      debugPrint('Failed to load lessons: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load lessons: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLessons = _lessons
        .where((lesson) => !lesson.isArchived)
        .toList();
    final archivedLessons = _lessons
        .where((lesson) => lesson.isArchived)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  Expanded(
                    child: Text(
                      widget.subjectName.isEmpty
                          ? 'Lessons'
                          : '${widget.subjectName} Lessons',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      child: _buildBody(activeLessons, archivedLessons),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Lesson> activeLessons, List<Lesson> archivedLessons) {
    if (_lessons.isEmpty) {
      return _emptyState('No lessons available for this class yet.');
    }

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      children: [
        _sectionHeader("Today's Lesson"),
        const SizedBox(height: 12),
        if (activeLessons.isEmpty)
          _inlineEmpty('Nothing active right now.')
        else
          ...activeLessons.map(_buildLessonCard),
        const SizedBox(height: 24),
        _sectionHeader(
          'Archived Lessons',
          trailing: const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primaryMid,
            size: 22,
          ),
        ),
        const SizedBox(height: 12),
        if (archivedLessons.isEmpty)
          _inlineEmpty('No archived lessons.')
        else
          ...archivedLessons.map(_buildLessonCard),
      ],
    );
  }

  Widget _emptyState(String text) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      ),
    );
  }

  Widget _sectionHeader(String label, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.objective.isEmpty ? 'Untitled lesson' : lesson.objective,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          if (lesson.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lesson.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  lesson.createdAt.isEmpty
                      ? 'No date available'
                      : 'Created: ${lesson.createdAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LessonOverviewScreen(lesson: lesson),
                    ),
                  );
                },
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CB07D),
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
