import 'package:flutter/material.dart';

class ParentBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ParentBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const String _iconPath = 'assets/images/bottom_navigation_bar_icon';
  static const Color _activeColor = Color(0xFF871DAD);
  static const Color _inactiveColor = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconAsset: '$_iconPath/home.png',
            label: "Home",
            index: 0,
          ),
          _buildNavItem(
            iconAsset: '$_iconPath/teacher.png',
            label: "Child's",
            index: 1,
          ),
          _buildNavItem(
            iconAsset: '$_iconPath/message.png',
            label: "Chat",
            index: 2,
          ),
          _buildNavItem(
            iconAsset: '$_iconPath/frofile.png',
            label: "Profile",
            index: 3,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 24,
              height: 24,
              color: isSelected ? _activeColor : _inactiveColor,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: isSelected
                  ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _activeColor,
                      ),
                    )
                  : const SizedBox(
                      height: 12,
                    ), // Placeholder to maintain vertical alignment
            ),
          ],
        ),
      ),
    );
  }
}
