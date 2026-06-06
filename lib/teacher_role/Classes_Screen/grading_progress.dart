import 'package:flutter/material.dart';
import 'scan_document.dart';

class GradingProgressScreen extends StatefulWidget {
  const GradingProgressScreen({Key? key}) : super(key: key);

  @override
  State<GradingProgressScreen> createState() => _GradingProgressScreenState();
}

class _GradingProgressScreenState extends State<GradingProgressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
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
          "Grading Progress",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanDocumentScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF871DAD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .center_focus_strong_outlined, // closest to the scan/focus icon
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _buildProgressCard(
              title: "Fractions Practice",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFF4AA678), // Green
            ),
            _buildProgressCard(
              title: "Photosynthesis",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFF3F99B4), // Blue
            ),
            _buildProgressCard(
              title: "Force and Motion",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFFFEBD43), // Yellow
            ),
            _buildProgressCard(
              title: "Fractions Practice",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFF4AA678), // Green
            ),
            _buildProgressCard(
              title: "Photosynthesis",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFF3F99B4), // Blue
            ),
            _buildProgressCard(
              title: "Force and Motion",
              date: "12/05/2025",
              progress: 0.93,
              indicatorColor: const Color(0xFFFEBD43), // Yellow
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String date,
    required double progress,
    required Color indicatorColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "0%",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF871DAD),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF871DAD),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF871DAD),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
