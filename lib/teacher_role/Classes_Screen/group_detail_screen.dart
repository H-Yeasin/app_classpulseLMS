import 'package:flutter/material.dart';
import 'student_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/teacher_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> roomData;
  final String classId;

  const GroupDetailScreen({
    super.key,
    required this.roomData,
    required this.classId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  late Map<String, dynamic> _currentRoom;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRoom = Map.from(widget.roomData);
  }

  Future<void> _removeMember(String studentId) async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final List<dynamic> participants = List.from(_currentRoom['participants']);
      
      // Remove the participant with this userId
      participants.removeWhere((p) => p['userId'] == studentId);

      final response = await apiClient.patch('/rooms/${_currentRoom['_id']}', data: {
        'participants': participants,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _currentRoom = response.data['data'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
          ref.invalidate(userRoomsProvider);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider(widget.classId));
    final homeworkAsync = ref.watch(classHomeworkProvider(widget.classId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _currentRoom['name'] ?? "Group Detail",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF871DAD),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF871DAD),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Members Title
                    Text(
                      "Members (${(_currentRoom['participants'] as List).length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Members List
                    studentsAsync.when(
                      data: (students) {
                        final participants = _currentRoom['participants'] as List;
                        
                        // Map of studentId -> studentData for quick lookup
                        final studentMap = {
                          for (var s in students)
                            if (s['studentId'] != null)
                              s['studentId']['_id']: s['studentId']
                        };

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final userId = participants[index]['userId'];
                            final student = studentMap[userId];
                            
                            // Skip if it's the teacher or student not found in this class
                            if (student == null) return const SizedBox();

                            return GestureDetector(
                              onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentProfileScreen(
                                        studentData: student,
                                        classId: widget.classId,
                                      ),
                                    ),
                                  );
                              },
                              child: _buildMemberCard(
                                id: userId,
                                name: student['username'] ?? student['name'] ?? 'Unknown',
                                avatarUrl: student['avatar'] is Map ? student['avatar']['url'] : student['avatar'],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text("Error loading members: $err")),
                    ),

                    const SizedBox(height: 24),

                    // Today's Homework
                    const Text(
                      "Today's Homework",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    homeworkAsync.when(
                      data: (homeworkList) {
                        if (homeworkList.isEmpty) {
                          return const Center(child: Text("No homework found."));
                        }
                        // For now just showing the first homework from the class as a placeholder
                        final hw = homeworkList[0];
                        return _buildHomeworkCard(
                          title: hw['title'] ?? 'No Title',
                          description: hw['description'] ?? 'No Description',
                          dueDate: hw['created_at'] != null 
                              ? "Created: ${hw['created_at'].toString().split('T')[0]}" 
                              : "Date: TBD",
                          showOptions: true,
                        );
                      },
                      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (err, stack) => Center(child: Text("Error: $err")),
                    ),
                    
                    const SizedBox(height: 32),

                    // Archived Homework Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Archived Homework",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF871DAD),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    homeworkAsync.when(
                      data: (homeworkList) {
                        if (homeworkList.length < 2) return const SizedBox();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: homeworkList.length - 1,
                          itemBuilder: (context, index) {
                            final hw = homeworkList[index + 1];
                            return _buildHomeworkCard(
                              title: hw['title'] ?? 'No Title',
                              description: hw['description'] ?? 'No Description',
                              dueDate: hw['created_at'] != null 
                                  ? "Created: ${hw['created_at'].toString().split('T')[0]}" 
                                  : "Date: TBD",
                              showOptions: false,
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (err, stack) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required String id,
    required String name,
    String? avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF3F4F6)),
            clipBehavior: Clip.hardEdge,
            child: avatarUrl != null && avatarUrl.isNotEmpty
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
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () => _removeMember(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF94A4A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _isLoading
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      "Remove",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard({
    required String title,
    required String description,
    required String dueDate,
    required bool showOptions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dueDate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (showOptions)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF871DAD),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF871DAD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF94A4A),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFF94A4A),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

