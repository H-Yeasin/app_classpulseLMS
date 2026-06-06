import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class StudentBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
              _buildNavItem(
                1,
                Icons.menu_book_outlined,
                Icons.menu_book,
                "Lessons",
              ),
              _buildNavItem(
                2,
                Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded,
                "Chat",
              ),
              _buildNavItem(
                3,
                Icons.lightbulb_outline_rounded,
                Icons.lightbulb_rounded,
                "Quiz",
              ),
              _buildNavItem(
                4,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected
        ? AppColors.primaryMid
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? filledIcon : outlineIcon, color: color, size: 26),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
