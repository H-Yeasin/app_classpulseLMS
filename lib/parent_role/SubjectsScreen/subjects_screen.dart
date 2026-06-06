import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/subject.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/subject_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final String initialChildId;
  final String? initialChildName;

  const SubjectsScreen({
    super.key,
    required this.initialChildId,
    this.initialChildName,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  late String _selectedChildId;
  List<ChildProfile> _children = [];
  List<Subject> _subjects = [];
  bool _isLoadingChildren = true;
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.initialChildId;
    _loadChildren();
    _loadSubjects(_selectedChildId);
  }

  Future<void> _loadChildren() async {
    try {
      final userData = await _storage.getUserData();
      if (userData == null) return;
      final parentId =
          (jsonDecode(userData)['id'] ?? jsonDecode(userData)['_id']).toString();

      final response =
          await _api.get(ApiConstants.childrenByParent(parentId));
      final List relations =
          (response.data is Map && response.data['data'] is Map)
              ? (response.data['data']['children'] as List? ?? const [])
              : const [];

      final children = relations
          .map((rel) {
            final child = rel['childId'];
            if (child is! Map) return null;
            return ChildProfile.fromJson(Map<String, dynamic>.from(child));
          })
          .whereType<ChildProfile>()
          .toList();

      if (!mounted) return;
      setState(() {
        _children = children;
      });
    } catch (e) {
      debugPrint('Failed to load children list: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingChildren = false);
      }
    }
  }

  Future<void> _loadSubjects(String childId) async {
    setState(() => _isLoadingSubjects = true);
    try {
      final response = await _api.get(ApiConstants.classesByStudent(childId));
      final classes = (response.data is Map && response.data['data'] is Map)
          ? (response.data['data']['classes'] as List? ?? const [])
          : const [];

      final subjects = classes
          .map((c) => Subject.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();

      if (!mounted) return;
      setState(() {
        _subjects = subjects;
      });
    } catch (e) {
      debugPrint('Failed to load subjects: $e');
      if (mounted) {
        setState(() => _subjects = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubjects = false);
      }
    }
  }

  void _onSelectChild(String childId) {
    if (childId == _selectedChildId) return;
    setState(() => _selectedChildId = childId);
    _loadSubjects(childId);
  }

  String _selectedChildName() {
    for (final c in _children) {
      if (c.id == _selectedChildId) return c.name;
    }
    return widget.initialChildName ?? '';
  }

  void _openSubjectDetail(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subject: subject,
          studentId: _selectedChildId,
          studentName: _selectedChildName(),
        ),
      ),
    );
  }

  ImageProvider? _avatarProvider(String url) {
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  Widget _initialFallback(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Text(
      letter,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
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
                  const Text(
                    "Subjects",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // ── Child Selector ──
            SizedBox(
              height: 70,
              child: _isLoadingChildren && _children.isEmpty
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        final bool isSelected = _selectedChildId == child.id;
                        return GestureDetector(
                          onTap: () => _onSelectChild(child.id),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryMid
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: _avatarProvider(child.imageUrl),
                              backgroundColor: Colors.grey.shade200,
                              child: child.imageUrl.isEmpty
                                  ? _initialFallback(child.name)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // ── Subjects List ──
            Expanded(
              child: _isLoadingSubjects
                  ? const Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No subjects assigned yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadSubjects(_selectedChildId),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: _subjects.length,
                            itemBuilder: (context, index) {
                              return _buildSubjectCard(_subjects[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return GestureDetector(
      onTap: () {
        _openSubjectDetail(subject);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Upper Part: Subject Info & Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMid,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // Stats
                  Row(
                    children: [
                      _buildStat(
                        Icons.calendar_today_rounded,
                        subject.attendance,
                      ),
                      const SizedBox(width: 14),
                      _buildStat(
                        Icons.bar_chart_rounded,
                        subject.performance,
                        color: const Color(0xFFF4B84F),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade100),

            // Lower Part: Teacher Info & View Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: _avatarProvider(subject.teacherAvatar),
                    backgroundColor: Colors.grey.shade200,
                    child: subject.teacherAvatar.isEmpty
                        ? _initialFallback(subject.teacherName)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.teacherName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          subject.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openSubjectDetail(subject),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMid,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "View",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildStat(
    IconData icon,
    String value, {
    Color color = const Color(0xFF4CB07D),
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}