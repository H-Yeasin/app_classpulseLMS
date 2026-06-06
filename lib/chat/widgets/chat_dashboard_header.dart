import 'package:flutter/material.dart';

class ChatDashboardHeader extends StatelessWidget {
  final VoidCallback onOpenCallHistory;
  final VoidCallback onOpenNotifications;

  const ChatDashboardHeader({
    super.key,
    required this.onOpenCallHistory,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 140,
          child: Image.asset(
            'assets/images/Home_dashboard_header.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    _HeaderIconButton(
                      imageAsset: 'assets/images/home_dashboard/call_icons.png',
                      onTap: onOpenCallHistory,
                    ),
                    const SizedBox(width: 12),
                    _HeaderIconButton(
                      imageAsset:
                          'assets/images/home_dashboard/notification.png',
                      onTap: onOpenNotifications,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.imageAsset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(child: Image.asset(imageAsset, width: 30, height: 30)),
      ),
    );
  }
}
