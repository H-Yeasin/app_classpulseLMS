import 'package:flutter/material.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/models/learning_tip.dart';

class LearningTipDetailScreen extends StatelessWidget {
  final LearningTip tip;

  const LearningTipDetailScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
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
                          color: Color(0xFF871DAD),
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
                      "Detail",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
              ),

              // Hero Image
              if (tip.imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      tip.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),

              // Legacy fallback: plain description when no sections are present
              if ((tip.sections == null || tip.sections!.isEmpty) &&
                  tip.description != null &&
                  tip.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    tip.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                ),

              // Dynamic contents mapping
              if (tip.sections != null)
                ...tip.sections!.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(section.title),
                      if (section.description != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            section.description!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      if (section.imageUrls != null &&
                          section.imageUrls!.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: section.imageUrls!.map((url) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildSmallImage(url),
                              );
                            }).toList(),
                          ),
                        ),
                      if (section.bulletPoints != null &&
                          section.bulletPoints!.isNotEmpty)
                        _buildBulletList(section.bulletPoints!),
                      if (section.footerText != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            section.footerText!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                    ],
                  );
                }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 4, color: Color(0xFF555555)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSmallImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, trace) => Container(
          width: 100,
          height: 100,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }
}
