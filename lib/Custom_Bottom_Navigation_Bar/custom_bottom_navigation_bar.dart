import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const String _iconPath = 'assets/images/bottom_navigation_bar_icon';
  static const Color _activeColor = Color(0xFF871DAD);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Custom Background with center hump ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 80,
              child: CustomPaint(painter: _BottomBarPainter()),
            ),
          ),

          // ── Nav items ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    iconAsset: '$_iconPath/home.png',
                    label: "Home",
                    index: 0,
                  ),
                  _buildNavItem(
                    iconAsset: '$_iconPath/classes.png',
                    label: "Classes",
                    index: 1,
                  ),
                  const SizedBox(width: 60), // Spacer for center button
                  _buildNavItem(
                    iconAsset: '$_iconPath/message.png',
                    label: "Message",
                    index: 3,
                  ),
                  _buildNavItem(
                    iconAsset: '$_iconPath/frofile.png',
                    label: "Profile",
                    index: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── Center FAB ──
          Positioned(
            bottom: 40,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _activeColor,
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      '$_iconPath/middle.png',
                      width: 30,
                      height: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Icon container with fixed height ensures all icons are at the same Y level
            SizedBox(
              height: 32,
              child: Center(
                child: Image.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  color: isSelected ? _activeColor : const Color(0xFF999999),
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _activeColor : const Color(0xFF999999),
                ),
              )
            else
              const SizedBox(
                height: 12,
              ), // Placeholder height to balance layout
          ],
        ),
      ),
    );
  }
}

class _BottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    const humpWidth = 100.0;
    const humpHeight = 32.0;
    const radius = 30.0;

    final path = Path()
      ..moveTo(0, radius)
      // Top left corner
      ..arcToPoint(
        const Offset(radius, 0),
        radius: const Radius.circular(radius),
      )
      ..lineTo(w / 2 - humpWidth / 2, 0)
      // Smooth hump curve
      ..cubicTo(
        w / 2 - humpWidth / 4,
        0,
        w / 2 - humpWidth / 3,
        -humpHeight,
        w / 2,
        -humpHeight,
      )
      ..cubicTo(
        w / 2 + humpWidth / 3,
        -humpHeight,
        w / 2 + humpWidth / 4,
        0,
        w / 2 + humpWidth / 2,
        0,
      )
      ..lineTo(w - radius, 0)
      // Top right corner
      ..arcToPoint(Offset(w, radius), radius: const Radius.circular(radius))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 12, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
