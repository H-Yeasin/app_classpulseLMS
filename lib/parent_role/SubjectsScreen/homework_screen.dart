import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/homework.dart';

enum HomeworkTab { classTab, groupsTab }

class HomeworkScreen extends StatefulWidget {
  final String classId;
  final String subjectName;

  const HomeworkScreen({
    super.key,
    required this.classId,
    required this.subjectName,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final ApiClient _api = ApiClient();

  HomeworkTab activeTab = HomeworkTab.classTab;
  List<Homework> _classHomework = [];
  List<GroupHomework> _groupHomework = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConstants.homeworkByClass(widget.classId)),
        _api.get(ApiConstants.groupWorkByClass(widget.classId)),
      ]);

      final classList = (results[0].data is Map &&
              results[0].data['data'] is List)
          ? (results[0].data['data'] as List)
          : const [];
      final groupList = (results[1].data is Map &&
              results[1].data['data'] is List)
          ? (results[1].data['data'] as List)
          : const [];

      if (!mounted) return;
      setState(() {
        _classHomework = classList
            .map((j) => Homework.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
        _groupHomework = groupList
            .map((j) =>
                GroupHomework.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load homework: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load homework: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Homework",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // ── Segmented Control (Toggle) ──
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton("Class", HomeworkTab.classTab),
                  _buildTabButton("Groups", HomeworkTab.groupsTab),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      child: _buildBody(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (activeTab == HomeworkTab.classTab) {
      final today = _classHomework.where((h) => !h.isArchived).toList();
      final archived = _classHomework.where((h) => h.isArchived).toList();

      if (_classHomework.isEmpty) {
        return _emptyState("No homework assigned to this class yet.");
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _sectionHeader("Today's Homework"),
          const SizedBox(height: 12),
          if (today.isEmpty)
            _inlineEmpty("Nothing active right now.")
          else
            ...today.map(_buildHomeworkCard),
          const SizedBox(height: 24),
          _sectionHeader("Archived Homework",
              trailing: const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primaryMid, size: 22)),
          const SizedBox(height: 12),
          if (archived.isEmpty)
            _inlineEmpty("No archived homework.")
          else
            ...archived.map(_buildHomeworkCard),
        ],
      );
    }

    final todayGroups = _groupHomework.where((h) => !h.isArchived).toList();
    final archivedGroups = _groupHomework.where((h) => h.isArchived).toList();

    if (_groupHomework.isEmpty) {
      return _emptyState("No group homework assigned to this class yet.");
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _sectionHeader("Today's Homework"),
        const SizedBox(height: 12),
        if (todayGroups.isEmpty)
          _inlineEmpty("Nothing active right now.")
        else
          ...todayGroups.map(_buildGroupHomeworkCard),
        const SizedBox(height: 24),
        _sectionHeader("Archived Homework",
            trailing: const Icon(Icons.calendar_month_rounded,
                color: AppColors.primaryMid, size: 22)),
        const SizedBox(height: 12),
        if (archivedGroups.isEmpty)
          _inlineEmpty("No archived group homework.")
        else
          ...archivedGroups.map(_buildGroupHomeworkCard),
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

  Widget _buildTabButton(String label, HomeworkTab tab) {
    bool isSelected = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMid : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(Homework hw) {
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
            hw.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          if (hw.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hw.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Text(
            hw.dueDate.isEmpty ? "No due date" : "Due: ${hw.dueDate}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHomeworkCard(GroupHomework hw) {
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
            hw.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          if (hw.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hw.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          if (hw.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hw.members.map(_buildMemberChip).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Text(
            hw.dueDate.isEmpty ? "No due date" : "Due: ${hw.dueDate}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip(GroupMember m) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage:
                m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
            backgroundColor: Colors.grey.shade300,
            child: m.avatarUrl.isEmpty
                ? Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            m.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
