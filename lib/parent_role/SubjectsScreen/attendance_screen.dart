import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  final String subjectName;
  final String classId;
  final String studentId;
  final String studentName;

  const AttendanceScreen({
    super.key,
    required this.subjectName,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiClient _api = ApiClient();

  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.get(
        ApiConstants.attendanceByStudent,
        queryParameters: {
          'userId': widget.studentId,
          'classId': widget.classId,
        },
      );

      final rawList = (response.data is Map &&
              response.data['data'] is Map &&
              response.data['data']['attendanceRecords'] is List)
          ? (response.data['data']['attendanceRecords'] as List)
          : const [];

      final records = rawList
          .map((j) => AttendanceRecord.fromJson(
                Map<String, dynamic>.from(j as Map),
                studentNameFallback: widget.studentName,
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _records = records;
      });
    } on DioException catch (e) {
      // Backend throws 404 when a student has no attendance yet — treat as empty.
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        setState(() {
          _records = [];
        });
      } else {
        debugPrint('Failed to load attendance: $e');
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load attendance';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('Failed to load attendance: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load attendance';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance: $e')),
      );
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
                    "Attendance",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // ── Attendance Table ──
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF4B84F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  "Date",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Students Name",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Status",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _records.isEmpty) {
      return _centeredMessage(_errorMessage!);
    }
    if (_records.isEmpty) {
      return _centeredMessage('No attendance records yet.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _records.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildAttendanceRow(_records[index]),
      ),
    );
  }

  Widget _centeredMessage(String text) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRow(AttendanceRecord record) {
    final Color statusBgColor;
    switch (record.status) {
      case AttendanceStatus.present:
        statusBgColor = const Color(0xFFD4EAE0); // light green
        break;
      case AttendanceStatus.absent:
        statusBgColor = const Color(0xFFF8D7D7); // light red
        break;
      case AttendanceStatus.tardy:
        statusBgColor = const Color(0xFFFCE5C5); // light amber
        break;
      case AttendanceStatus.holiday:
        statusBgColor = const Color(0xFFD7E5F8); // light blue
        break;
      case AttendanceStatus.unknown:
        statusBgColor = const Color(0xFFE8E8E8); // grey
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              record.date,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              record.studentName,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}