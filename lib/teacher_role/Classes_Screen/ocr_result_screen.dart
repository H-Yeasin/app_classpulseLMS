import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OCRResultScreen extends StatefulWidget {
  final String imagePath;
  final String text;

  const OCRResultScreen({
    super.key,
    required this.imagePath,
    required this.text,
  });

  @override
  State<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  bool _isEditing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFE8EAF6)],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildImagePreview(),
                          _buildPaperSheet(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Glassmorphic Bottom Bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Paper Preview",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              _buildActionButton(
                icon: _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                onPressed: () {
                  setState(() => _isEditing = !_isEditing);
                  if (!_isEditing) {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Changes saved"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.copy_all_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Copied to clipboard"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF871DAD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF871DAD), size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(widget.imagePath), fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
              const Positioned(
                bottom: 12,
                left: 16,
                child: Row(
                  children: [
                    Icon(Icons.image_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Original Scan Source",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperSheet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: CustomPaint(
          painter: PremiumPaperPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(70, 50, 30, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaperHeader(),
                const SizedBox(height: 30),
                _isEditing
                    ? TextFormField(
                        controller: _controller,
                        maxLines: null,
                        style: _paperTextStyle(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      )
                    : SelectableText(
                        _controller.text.isEmpty
                            ? "No text detected."
                            : _controller.text,
                        style: _paperTextStyle(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaperHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SCAN DOCUMENT",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.8),
            fontFamily: 'serif',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 3, width: 60, color: const Color(0xFF871DAD)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerInfo("Date:", DateTime.now().toString().split(' ')[0]),
            _headerInfo("Subject:", "Question"),
          ],
        ),
      ],
    );
  }

  Widget _headerInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.0),
            border: Border(
              top: BorderSide(color: Colors.black.withOpacity(0.00)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF871DAD), Color(0xFF9C27B0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF871DAD).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "FINALIZE & USE DOCUMENT",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _paperTextStyle() {
    return const TextStyle(
      fontSize: 17,
      height: 2.2,
      color: Color(0xFF1A1A1A),
      fontFamily: 'serif',
      letterSpacing: 0.1,
    );
  }
}

class PremiumPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..strokeWidth = 0.5;

    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..strokeWidth = 1.2;

    final holePaint = Paint()
      ..color = const Color(0xFFF0F2F5)
      ..style = PaintingStyle.fill;

    // Draw horizontal lines
    const double lineSpacing = 17 * 2.2;
    for (double i = 180; i < size.height; i += lineSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // Draw vertical margin
    canvas.drawLine(const Offset(55, 0), Offset(55, size.height), marginPaint);

    // Draw binding holes
    for (double i = 100; i < size.height; i += 150) {
      canvas.drawCircle(Offset(25, i), 8, holePaint);
      canvas.drawCircle(
        Offset(25, i),
        8,
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
