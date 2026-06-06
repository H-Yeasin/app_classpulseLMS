import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _generalNotifications = true;
  bool _sound = false;
  bool _vibrate = true;
  bool _specialOffers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
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
                  const Text(
                    "Notification Settings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Settings List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildToggleTile(
                    title: "General Notifications",
                    value: _generalNotifications,
                    onChanged: (val) =>
                        setState(() => _generalNotifications = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  _buildToggleTile(
                    title: "Sound",
                    value: _sound,
                    onChanged: (val) => setState(() => _sound = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  _buildToggleTile(
                    title: "Vibrate",
                    value: _vibrate,
                    onChanged: (val) => setState(() => _vibrate = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  _buildToggleTile(
                    title: "Special Offers",
                    value: _specialOffers,
                    onChanged: (val) => setState(() => _specialOffers = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryMid,
            inactiveTrackColor: const Color(0xFFD9D9D9),
          ),
        ],
      ),
    );
  }
}
