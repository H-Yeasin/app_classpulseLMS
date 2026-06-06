import 'package:flutter/material.dart';

class ChatDashboardTabs extends StatelessWidget {
  final int selectedTab;
  final String groupTabLabel;
  final ValueChanged<int> onChanged;

  const ChatDashboardTabs({
    super.key,
    required this.selectedTab,
    required this.groupTabLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabItem(
                title: 'Chat',
                index: 0,
                selectedTab: selectedTab,
                onChanged: onChanged,
              ),
            ),
            Expanded(
              child: _TabItem(
                title: 'Draft',
                index: 1,
                selectedTab: selectedTab,
                onChanged: onChanged,
              ),
            ),
            Expanded(
              child: _TabItem(
                title: groupTabLabel,
                index: 2,
                selectedTab: selectedTab,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final int index;
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _TabItem({
    required this.title,
    required this.index,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF871DAD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
