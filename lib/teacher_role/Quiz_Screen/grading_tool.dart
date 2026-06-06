import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/grading_provider.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/quiz_details.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/create_quiz.dart';
import 'package:opalmer_education/teacher_role/Classes_Screen/scan_document.dart';

class GradingToolScreen extends ConsumerStatefulWidget {
  const GradingToolScreen({super.key});

  @override
  ConsumerState<GradingToolScreen> createState() => _GradingToolScreenState();
}

class _GradingToolScreenState extends ConsumerState<GradingToolScreen> {
  bool _isDraftTab = true;
  String? _publishingSessionId;

  Future<void> _publishDraft(String sessionId) async {
    setState(() => _publishingSessionId = sessionId);

    final success = await ref
        .read(gradingActionProvider.notifier)
        .publishSession(sessionId);

    if (!mounted) return;
    setState(() => _publishingSessionId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Quiz published successfully'
              : 'Failed to publish quiz. Please check that it has questions.',
        ),
      ),
    );

    if (success) {
      setState(() => _isDraftTab = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(teacherSessionsProvider(null));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'grading_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateQuizScreen()),
          );
        },
        backgroundColor: const Color(0xFF871DAD),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Tab Switcher
          const SizedBox(height: 24),
          _buildTabSwitcher(),

          // Grading List
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                final filteredSessions = sessions.where((s) {
                  final status = s['status']?.toString().toLowerCase();
                  return _isDraftTab
                      ? status == 'draft'
                      : status == 'published';
                }).toList();

                if (filteredSessions.isEmpty) {
                  return Center(
                    child: Text(
                      _isDraftTab
                          ? "No draft sessions found"
                          : "No published sessions found",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(teacherSessionsProvider(null).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final sessionId = session['_id']?.toString() ?? '';
                      String imageUrl =
                          "https://img.freepik.com/free-photo/view-planet-earth-from-space_23-2148705432.jpg";
                      if (session['image'] != null &&
                          session['image'].toString().isNotEmpty) {
                        imageUrl = session['image'].toString();
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuizDetailScreen(sessionId: sessionId),
                            ),
                          );
                        },
                        child: _buildGradingItem(
                          title: session['title'] ?? 'Untitled',
                          questions:
                              "${session['questionCount'] ?? 0} Questions",
                          time: "${session['time'] ?? 0} min",
                          status: _isDraftTab ? "Draft" : "Published",
                          imageUrl: imageUrl,
                          isPublishing: _publishingSessionId == sessionId,
                          onPublish: _isDraftTab && sessionId.isNotEmpty
                              ? () => _publishDraft(sessionId)
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Home_dashboard_header.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Grading Tool",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (!_isDraftTab)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanDocumentScreen(),
                  ),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.center_focus_strong_outlined,
                  color: Color(0xFF871DAD),
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDraftTab = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDraftTab
                      ? const Color(0xFF871DAD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Draft",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isDraftTab ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDraftTab = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isDraftTab
                      ? const Color(0xFF871DAD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Publish",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: !_isDraftTab ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingItem({
    required String title,
    required String questions,
    required String time,
    required String status,
    required String imageUrl,
    VoidCallback? onPublish,
    bool isPublishing = false,
  }) {
    final bool isDraft = status == "Draft";
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$questions · $time",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDraft
                      ? const Color(0xFFFFCC33).withValues(alpha: 0.2)
                      : const Color(0xFF4FA0F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDraft
                        ? const Color(0xFFF39C12)
                        : const Color(0xFF007AFF),
                  ),
                ),
              ),
              if (onPublish != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isPublishing ? null : onPublish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF871DAD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Publish',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
