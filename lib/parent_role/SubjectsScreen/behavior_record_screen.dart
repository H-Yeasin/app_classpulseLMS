import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/behavior.dart';

class BehaviorRecordScreen extends StatefulWidget {
  final String subjectName;
  final String childId;
  final String childName;

  const BehaviorRecordScreen({
    super.key,
    required this.subjectName,
    required this.childId,
    required this.childName,
  });

  @override
  State<BehaviorRecordScreen> createState() => _BehaviorRecordScreenState();
}

class _BehaviorRecordScreenState extends State<BehaviorRecordScreen> {
  final ApiClient _api = ApiClient();

  List<BehaviorRecord> _records = [];
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
        ApiConstants.studentBehaviors,
        queryParameters: {'childId': widget.childId},
      );

      final rawList = response.data is Map && response.data['data'] is List
          ? response.data['data'] as List
          : const [];

      final records = rawList
          .whereType<Map>()
          .map(
            (json) => BehaviorRecord.fromJson(
              Map<String, dynamic>.from(json),
              studentNameFallback: widget.childName,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() => _records = records);
    } on DioException catch (e) {
      debugPrint('Failed to load behavior records: $e');
      if (!mounted) return;
      setState(() {
        _records = [];
        _errorMessage = e.response?.statusCode == 404
            ? null
            : 'Failed to load behavior records';
      });
      if (e.response?.statusCode != 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load behavior records: ${e.message}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to load behavior records: $e');
      if (!mounted) return;
      setState(() {
        _records = [];
        _errorMessage = 'Failed to load behavior records';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load behavior records: $e')),
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
                    "Behavior Record",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // ── Behavior List ──
            Expanded(child: _buildBody()),
          ],
        ),
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
      return _centeredMessage('No behavior records yet.');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          return _buildBehaviorCard(_records[index]);
        },
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorCard(BehaviorRecord record) {
    final bool isPositive = record.type == BehaviorType.positive;
    final Color tagBgColor = isPositive
        ? const Color(0xFFD4EAE0)
        : const Color(0xFFF8D7D7);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Part: Description & Tag
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.typeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // Lower Part: Teacher Info & Date
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTeacherAvatar(record),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.teacherName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
                Text(
                  record.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherAvatar(BehaviorRecord record) {
    if (record.teacherAvatar.isEmpty) {
      final initial = record.teacherName.trim().isNotEmpty
          ? record.teacherName.trim()[0].toUpperCase()
          : 'T';
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundImage: NetworkImage(record.teacherAvatar),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
