import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/download_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/academic_document.dart';
import 'package:printing/printing.dart';

class AcademicDocumentsScreen extends StatefulWidget {
  final String subjectName;
  final String childId;
  final String childName;

  const AcademicDocumentsScreen({
    super.key,
    required this.subjectName,
    required this.childId,
    required this.childName,
  });

  @override
  State<AcademicDocumentsScreen> createState() =>
      _AcademicDocumentsScreenState();
}

class _AcademicDocumentsScreenState extends State<AcademicDocumentsScreen> {
  final ApiClient _api = ApiClient();

  List<AcademicDocument> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(
        ApiConstants.childAcademicDocuments,
        queryParameters: {'childId': widget.childId},
      );

      final rawList = response.data is Map && response.data['data'] is List
          ? response.data['data'] as List
          : const [];

      final documents = rawList
          .whereType<Map>()
          .map(
            (json) => AcademicDocument.fromJson(
              Map<String, dynamic>.from(json),
              studentNameFallback: widget.childName,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() => _documents = documents);
    } on DioException catch (error) {
      debugPrint('Failed to load academic documents: $error');
      if (!mounted) return;
      setState(() {
        _documents = [];
        _errorMessage = error.response?.statusCode == 404
            ? null
            : 'Failed to load academic documents.';
      });
      if (error.response?.statusCode != 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load academic documents: ${error.message}',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Failed to load academic documents: $error');
      if (!mounted) return;
      setState(() {
        _documents = [];
        _errorMessage = 'Failed to load academic documents.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load academic documents: $error')),
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
                      "Academic Documents",
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

    if (_errorMessage != null && _documents.isEmpty) {
      return _centeredMessage(_errorMessage!);
    }

    if (_documents.isEmpty) {
      return _centeredMessage('No academic documents yet.');
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentCard(context, _documents[index]);
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

  Widget _buildDocumentCard(BuildContext context, AcademicDocument doc) {
    final type = _documentType(doc.downloadUrl);
    final canPreview = doc.downloadUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canPreview
            ? () => _openDocumentViewer(context, doc, type)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                      doc.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _documentSubtitle(doc, type),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (canPreview) ...[
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

  String _documentSubtitle(AcademicDocument doc, _AcademicDocumentType type) {
    final actionText = type == _AcademicDocumentType.pdf
        ? 'Tap to view PDF'
        : type == _AcademicDocumentType.image
        ? 'Tap to view image'
        : doc.downloadUrl.isEmpty
        ? 'No file attached'
        : 'Tap to view document';
    final meta = [
      if (doc.teacherName.isNotEmpty) doc.teacherName,
      if (doc.date.isNotEmpty) doc.date,
    ].join(' - ');

    return meta.isEmpty ? actionText : '$actionText\n$meta';
  }

  void _openDocumentViewer(
    BuildContext context,
    AcademicDocument doc,
    _AcademicDocumentType type,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _AcademicDocumentViewerDialog(
        title: doc.title,
        url: doc.downloadUrl,
        type: type,
      ),
    );
  }

  static _AcademicDocumentType _documentType(String url) {
    if (url.isEmpty) return _AcademicDocumentType.none;

    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();

    if (path.endsWith('.pdf')) return _AcademicDocumentType.pdf;

    const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];
    if (imageExtensions.any(path.endsWith)) {
      return _AcademicDocumentType.image;
    }

    return _AcademicDocumentType.other;
  }

  static IconData _documentIcon(_AcademicDocumentType type) {
    switch (type) {
      case _AcademicDocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case _AcademicDocumentType.image:
        return Icons.image_rounded;
      case _AcademicDocumentType.other:
        return Icons.insert_drive_file_rounded;
      case _AcademicDocumentType.none:
        return Icons.insert_drive_file_outlined;
    }
  }
}

enum _AcademicDocumentType { pdf, image, other, none }

class _AcademicDocumentViewerDialog extends StatefulWidget {
  final String title;
  final String url;
  final _AcademicDocumentType type;

  const _AcademicDocumentViewerDialog({
    required this.title,
    required this.url,
    required this.type,
  });

  @override
  State<_AcademicDocumentViewerDialog> createState() =>
      _AcademicDocumentViewerDialogState();
}

class _AcademicDocumentViewerDialogState
    extends State<_AcademicDocumentViewerDialog> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'classpluse/downloads',
  );

  late final Future<Uint8List>? _pdfBytes;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.type == _AcademicDocumentType.pdf
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
            'isImage': widget.type == _AcademicDocumentType.image,
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
                    _AcademicDocumentsScreenState._documentIcon(widget.type),
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
      case _AcademicDocumentType.pdf:
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
      case _AcademicDocumentType.image:
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
      case _AcademicDocumentType.other:
        return const _PreviewError(
          message: 'Preview is available for PDF and image files.',
        );
      case _AcademicDocumentType.none:
        return const _PreviewError(message: 'No document attached.');
    }
  }

  static String _safeFileName(String title, String url) {
    final uri = Uri.tryParse(url);
    final urlName = uri?.pathSegments.isNotEmpty == true
        ? Uri.decodeComponent(uri!.pathSegments.last)
        : '';
    final fallback = title.trim().isNotEmpty
        ? title.trim()
        : 'academic-document';
    final original = urlName.trim().isNotEmpty ? urlName.trim() : fallback;
    final sanitized = original.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return sanitized.isEmpty ? 'academic-document' : sanitized;
  }

  static String _mimeType(String fileName, _AcademicDocumentType type) {
    final lowerName = fileName.toLowerCase();

    if (type == _AcademicDocumentType.pdf || lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.gif')) return 'image/gif';
    if (lowerName.endsWith('.bmp')) return 'image/bmp';
    if (type == _AcademicDocumentType.image ||
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
