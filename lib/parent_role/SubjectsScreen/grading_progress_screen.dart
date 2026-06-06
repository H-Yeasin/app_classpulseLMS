import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/grading.dart';

class GradingProgressScreen extends StatefulWidget {
  final String subjectName;
  final String childId;
  final String classId;

  const GradingProgressScreen({
    super.key,
    required this.subjectName,
    required this.childId,
    required this.classId,
  });

  @override
  State<GradingProgressScreen> createState() => _GradingProgressScreenState();
}

class _GradingProgressScreenState extends State<GradingProgressScreen> {
  final ApiClient _api = ApiClient();

  GradingProgressData? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(
        ApiConstants.childGradingProgress,
        queryParameters: {'childId': widget.childId, 'classId': widget.classId},
      );

      final rawData = response.data is Map ? response.data['data'] : null;
      final progress = rawData is Map
          ? GradingProgressData.fromJson(Map<String, dynamic>.from(rawData))
          : const GradingProgressData(
              overallPercentage: 0,
              completedCount: 0,
              records: [],
            );

      if (!mounted) return;
      setState(() => _progress = progress);
    } on DioException catch (error) {
      debugPrint('Failed to load grading progress: $error');
      if (!mounted) return;
      setState(() {
        _progress = null;
        _errorMessage = error.response?.statusCode == 404
            ? null
            : 'Failed to load grading progress.';
      });
      if (error.response?.statusCode != 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load grading progress: ${error.message}'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Failed to load grading progress: $error');
      if (!mounted) return;
      setState(() {
        _progress = null;
        _errorMessage = 'Failed to load grading progress.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load grading progress: $error')),
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
                  const Expanded(
                    child: Text(
                      "Grading Progress",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    final progress = _progress;
    if (_errorMessage != null && (progress?.records.isEmpty ?? true)) {
      return _centeredMessage(_errorMessage!);
    }

    if (progress == null || progress.records.isEmpty) {
      return _centeredMessage('No grading progress yet.');
    }

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: progress.records.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildSummaryCard(progress);
          return _buildGradingCard(progress.records[index - 1], index - 1);
        },
      ),
    );
  }

  Widget _centeredMessage(String text) {
    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView(
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
      ),
    );
  }

  Widget _buildSummaryCard(GradingProgressData progress) {
    final progressValue = (progress.overallPercentage / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          Text(
            widget.subjectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedCount} completed grading session${progress.completedCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${progress.overallPercentage}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progressValue,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingCard(GradingRecord record, int index) {
    final accentColors = [
      const Color(0xFF4CB07D),
      const Color(0xFF3B97CB),
      const Color(0xFFF4B84F),
    ];
    final accentColor = accentColors[index % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        record.scoreLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryMid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _recordMeta(record),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "0%",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryMid.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        record.percentageLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryMid.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: record.percentage.clamp(0.0, 1.0),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryMid,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _recordMeta(GradingRecord record) {
    final parts = [
      if (record.date.isNotEmpty) record.date,
      if (record.classSubject.isNotEmpty) record.classSubject,
      if (record.teacherName.isNotEmpty) record.teacherName,
    ];
    return parts.join(' - ');
  }
}
