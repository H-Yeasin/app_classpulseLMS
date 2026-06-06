import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opalmer_education/core/services/download_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/lesson.dart';
import 'package:printing/printing.dart';

class LessonOverviewScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonOverviewScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        'Lessons Overview',
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
              const SizedBox(height: 12),
              _buildSection(
                title: 'Objective',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.objective.isEmpty
                            ? 'No objective provided.'
                            : lesson.objective,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (lesson.createdAt.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Text(
                        lesson.createdAt,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Document',
                child: _buildDocumentCard(context),
              ),
              const SizedBox(height: 32),
              _buildSection(
                title: 'Note',
                child: Text(
                  lesson.note.isEmpty ? 'No note provided.' : lesson.note,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context) {
    final type = _documentType(lesson.documentUrl);
    final hasDocument = lesson.documentUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: hasDocument ? () => _openDocumentViewer(context, type) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_documentIcon(type), color: AppColors.primaryMid, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.documentTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    if (hasDocument) ...[
                      const SizedBox(height: 6),
                      Text(
                        type == _LessonDocumentType.pdf
                            ? 'Tap to view PDF'
                            : type == _LessonDocumentType.image
                            ? 'Tap to view image'
                            : 'Tap to view document',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasDocument) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.primaryMid,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDocumentViewer(BuildContext context, _LessonDocumentType type) {
    showDialog<void>(
      context: context,
      builder: (context) => _LessonDocumentViewerDialog(
        title: lesson.documentTitle,
        url: lesson.documentUrl,
        type: type,
      ),
    );
  }

  static _LessonDocumentType _documentType(String url) {
    if (url.isEmpty) return _LessonDocumentType.none;

    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();

    if (path.endsWith('.pdf')) return _LessonDocumentType.pdf;

    const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];
    if (imageExtensions.any(path.endsWith)) return _LessonDocumentType.image;

    return _LessonDocumentType.other;
  }

  static IconData _documentIcon(_LessonDocumentType type) {
    switch (type) {
      case _LessonDocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case _LessonDocumentType.image:
        return Icons.image_rounded;
      case _LessonDocumentType.other:
        return Icons.insert_drive_file_rounded;
      case _LessonDocumentType.none:
        return Icons.insert_drive_file_outlined;
    }
  }
}

enum _LessonDocumentType { pdf, image, other, none }

class _LessonDocumentViewerDialog extends StatefulWidget {
  final String title;
  final String url;
  final _LessonDocumentType type;

  const _LessonDocumentViewerDialog({
    required this.title,
    required this.url,
    required this.type,
  });

  @override
  State<_LessonDocumentViewerDialog> createState() =>
      _LessonDocumentViewerDialogState();
}

class _LessonDocumentViewerDialogState
    extends State<_LessonDocumentViewerDialog> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'classpluse/downloads',
  );

  late final Future<Uint8List>? _pdfBytes;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.type == _LessonDocumentType.pdf
        ? _downloadBytes()
        : null;
  }

  Future<Uint8List> _downloadBytes() async {
    final dio = dioForDownloadUrl(widget.url);
    final response = await dio.get<List<int>>(
      widget.url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<void> _downloadDocument() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    try {
      final fileName = _safeFileName(widget.title, widget.url);
      final mimeType = _mimeType(fileName, widget.type);
      final dio = dioForDownloadUrl(widget.url);
      final response = await dio.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      final savedTo = await _downloadsChannel
          .invokeMethod<String>('saveToClassPluse', {
            'bytes': bytes,
            'fileName': fileName,
            'mimeType': mimeType,
            'isImage': widget.type == _LessonDocumentType.image,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(savedTo ?? 'Downloaded')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.82,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(
                    LessonOverviewScreen._documentIcon(widget.type),
                    color: AppColors.primaryMid,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Download',
                    onPressed: _isDownloading ? null : _downloadDocument,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    color: AppColors.primaryMid,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildViewer()),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    switch (widget.type) {
      case _LessonDocumentType.pdf:
        return PdfPreview(
          build: (_) => _pdfBytes!,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          useActions: false,
          pdfFileName: _safeFileName(widget.title, widget.url),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          onError: (context, error) => _PreviewError(message: error.toString()),
        );
      case _LessonDocumentType.image:
        return Container(
          color: const Color(0xFFF7F7F7),
          alignment: Alignment.center,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              widget.url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  _PreviewError(message: error.toString()),
            ),
          ),
        );
      case _LessonDocumentType.other:
        return const _PreviewError(
          message: 'Preview is available for PDF and image files.',
        );
      case _LessonDocumentType.none:
        return const _PreviewError(message: 'No document attached.');
    }
  }

  static String _safeFileName(String title, String url) {
    final uri = Uri.tryParse(url);
    final urlName = uri?.pathSegments.isNotEmpty == true
        ? Uri.decodeComponent(uri!.pathSegments.last)
        : '';
    final fallback = title.trim().isNotEmpty ? title.trim() : 'lesson-document';
    final original = urlName.trim().isNotEmpty ? urlName.trim() : fallback;
    final sanitized = original.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return sanitized.isEmpty ? 'lesson-document' : sanitized;
  }

  static String _mimeType(String fileName, _LessonDocumentType type) {
    final lowerName = fileName.toLowerCase();

    if (type == _LessonDocumentType.pdf || lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.gif')) return 'image/gif';
    if (lowerName.endsWith('.bmp')) return 'image/bmp';
    if (type == _LessonDocumentType.image ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }
}

class _PreviewError extends StatelessWidget {
  final String message;

  const _PreviewError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColors.primaryMid,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
