import 'dart:io';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/services/download_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class StudentLessonOverviewScreen extends StatefulWidget {
  final LessonModel lesson;
  const StudentLessonOverviewScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<StudentLessonOverviewScreen> createState() => _StudentLessonOverviewScreenState();
}

class _StudentLessonOverviewScreenState extends State<StudentLessonOverviewScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  Future<void> _downloadAndOpenFile(BuildContext context, String url, String fileName) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      // 1. Get Directory
      final directory = Platform.isAndroid 
          ? await getExternalStorageDirectory() 
          : await getApplicationDocumentsDirectory();
      
      final filePath = "${directory!.path}/$fileName.pdf";

      // 2. Download
      final dio = dioForDownloadUrl(url);
      await dio.download(
        url, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() => _isDownloading = false);

      // 3. Open File
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open file: ${result.message}")),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.lesson.createdAt != null 
      ? "${widget.lesson.createdAt!.day}/${widget.lesson.createdAt!.month}/${widget.lesson.createdAt!.year}" 
      : "N/A";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic Section
            const Text(
              "Topic",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.lesson.objective,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PDF Material Section
            if (widget.lesson.documentUrl != null && widget.lesson.documentUrl!.isNotEmpty) ...[
              const Text(
                "Learning Material",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isDownloading ? null : () => _downloadAndOpenFile(context, widget.lesson.documentUrl!, widget.lesson.objective),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMid.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primaryMid.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFFF4757),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lesson.objective,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDownloading 
                                ? "Downloading... ${(_downloadProgress * 100).toInt()}%" 
                                : "Tap to download PDF",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _isDownloading ? AppColors.primaryMid : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isDownloading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _downloadProgress,
                            strokeWidth: 3,
                            color: AppColors.primaryMid,
                            backgroundColor: AppColors.primaryMid.withValues(alpha: 0.1),
                          ),
                        )
                      else
                        const Icon(
                          Icons.download_for_offline_rounded,
                          color: AppColors.primaryMid,
                          size: 32,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Description Section
            const Text(
              "Description / Note",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                widget.lesson.note,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryMid.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryMid,
              size: 16,
            ),
          ),
        ),
      ),
      title: const Text(
        "Lesson Details",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
