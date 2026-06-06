import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/models/teacher_class_model.dart';
import '../../core/providers/teacher_provider.dart';

class AssignStudentsScreen extends ConsumerStatefulWidget {
  final TeacherClassModel classData;

  const AssignStudentsScreen({
    super.key,
    required this.classData,
  });

  @override
  ConsumerState<AssignStudentsScreen> createState() =>
      _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends ConsumerState<AssignStudentsScreen> {
  final Set<String> _selectedStudentIds = {};
  final Map<String, String> _existingAssignmentIds = {};
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final responses = await Future.wait([
        apiClient.get('/users/my-school/students/grade/${widget.classData.grade}'),
        apiClient.get('/student-assign-to-class/class/${widget.classData.id}'),
      ]);

      final studentsData = responses[0].data['data'];
      final assignmentsData = responses[1].data['data'];

      final students = studentsData is List
          ? studentsData
              .whereType<Map>()
              .map((student) => Map<String, dynamic>.from(student))
              .toList()
          : <Map<String, dynamic>>[];

      final existingAssignmentIds = <String, String>{};
      final selectedStudentIds = <String>{};

      if (assignmentsData is List) {
        for (final rawAssignment in assignmentsData.whereType<Map>()) {
          final assignment = Map<String, dynamic>.from(rawAssignment);
          final rawStudent = assignment['studentId'];
          final studentId = rawStudent is Map
              ? rawStudent['_id']?.toString()
              : rawStudent?.toString();
          final assignmentId = assignment['_id']?.toString();

          if (studentId != null && assignmentId != null) {
            selectedStudentIds.add(studentId);
            existingAssignmentIds[studentId] = assignmentId;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudentIds
          ..clear()
          ..addAll(selectedStudentIds);
        _existingAssignmentIds
          ..clear()
          ..addAll(existingAssignmentIds);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final existingStudentIds = _existingAssignmentIds.keys.toSet();
      final studentsToAdd = _selectedStudentIds.difference(existingStudentIds);
      final studentsToRemove = existingStudentIds.difference(_selectedStudentIds);

      for (final studentId in studentsToAdd) {
        await apiClient.post(
          '/student-assign-to-class',
          data: {
            'studentId': studentId,
            'classId': widget.classData.id,
          },
        );
      }

      for (final studentId in studentsToRemove) {
        final assignmentId = _existingAssignmentIds[studentId];
        if (assignmentId != null) {
          await apiClient.delete('/student-assign-to-class/$assignmentId');
        }
      }

      ref.invalidate(teacherClassesProvider);
      ref.invalidate(classStudentsProvider(widget.classData.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Students assigned successfully')),
      );
      Navigator.pop(context, _selectedStudentIds.length);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _students;

    return _students.where((student) {
      final name = student['username']?.toString().toLowerCase() ?? '';
      final id = student['Id']?.toString().toLowerCase() ?? '';
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  void _selectAllVisible() {
    setState(() {
      for (final student in _filteredStudents) {
        final studentId = student['_id']?.toString();
        if (studentId != null) _selectedStudentIds.add(studentId);
      }
    });
  }

  void _clearAllVisible() {
    setState(() {
      for (final student in _filteredStudents) {
        final studentId = student['_id']?.toString();
        if (studentId != null) _selectedStudentIds.remove(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
        title: const Text(
          'Assign Students',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || _isLoading ? null : _saveAssignments,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF871DAD),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'ASSIGN ${_selectedStudentIds.length} STUDENTS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading students: $_errorMessage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filteredStudents = _filteredStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grade ${widget.classData.grade} - ${widget.classData.subject}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              if (widget.classData.section?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  'Section ${widget.classData.section}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search students',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF871DAD)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_selectedStudentIds.length} selected',
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: filteredStudents.isEmpty ? null : _selectAllVisible,
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: filteredStudents.isEmpty ? null : _clearAllVisible,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredStudents.isEmpty
              ? const Center(child: Text('No students found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentTile(student);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student) {
    final studentId = student['_id']?.toString() ?? '';
    final isSelected = _selectedStudentIds.contains(studentId);
    final avatarUrl = ApiConstants.buildImageUrl(
      student['avatar'] is Map ? student['avatar']['url']?.toString() : null,
    );

    return InkWell(
      onTap: studentId.isEmpty
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedStudentIds.remove(studentId);
                } else {
                  _selectedStudentIds.add(studentId);
                }
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7ECFB) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF871DAD) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF3F4F6),
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF871DAD))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['username']?.toString() ?? 'Unnamed student',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${student['Id'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              activeColor: const Color(0xFF871DAD),
              onChanged: studentId.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(studentId);
                        } else {
                          _selectedStudentIds.remove(studentId);
                        }
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}
