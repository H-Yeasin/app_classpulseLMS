import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/providers/student_provider.dart';
import 'package:opalmer_education/core/services/download_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class StudentAcademicNotesScreen extends ConsumerStatefulWidget {
  const StudentAcademicNotesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentAcademicNotesScreen> createState() => _StudentAcademicNotesScreenState();
}

class _StudentAcademicNotesScreenState extends ConsumerState<StudentAcademicNotesScreen> {
  String? _downloadingId;
  double _progress = 0;

  Future<void> _downloadAndOpenFile(BuildContext context, String url, String id, String dateStr) async {
    try {
      setState(() {
        _downloadingId = id;
        _progress = 0;
      });

      final directory = Platform.isAndroid 
          ? await getExternalStorageDirectory() 
          : await getApplicationDocumentsDirectory();
      
      final filePath = "${directory!.path}/Academic_Note_$dateStr.pdf";

      final dio = dioForDownloadUrl(url);
      await dio.download(
        url, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() => _downloadingId = null);

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open file: ${result.message}")),
        );
      }
    } catch (e) {
      setState(() => _downloadingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(studentAcademicDocumentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentAcademicDocumentsProvider.future),
        color: AppColors.primaryMid,
        child: documentsAsync.when(
          data: (documents) {
            if (documents.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_rounded,
                            size: 64, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text(
                          "No academic notes found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = documents[index];
                final dateStr = doc.createdAt != null
                    ? "${doc.createdAt!.day}_${doc.createdAt!.month}_${doc.createdAt!.year}"
                    : "Unknown";

                final isDownloading = _downloadingId == doc.id;

                return _buildDocumentCard(
                  context,
                  doc,
                  doc.teacherName != null
                      ? "Note from ${doc.teacherName}"
                      : "Academic Note - ${dateStr.replaceAll('_', '/')}",
                  dateStr,
                  isDownloading,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
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
        "Academic Notes",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, AcademicDocumentModel doc, String title, String dateStr, bool isDownloading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF6C5CE7),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doc.createdAt != null)
              Text(
                "Uploaded: ${doc.createdAt!.day}/${doc.createdAt!.month}/${doc.createdAt!.year}",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              isDownloading
                  ? "Downloading... ${(_progress * 100).toInt()}%"
                  : "Tap to download & open",
              style: TextStyle(
                fontSize: 12,
                color: isDownloading ? AppColors.primaryMid : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isDownloading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 3,
                color: AppColors.primaryMid,
              ),
            )
          : GestureDetector(
              onTap: () {
                if (doc.url != null) {
                  _downloadAndOpenFile(context, doc.url!, doc.id, dateStr);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryMid,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
      ),
    );
  }
}
