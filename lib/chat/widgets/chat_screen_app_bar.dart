import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

class ChatScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? avatarUrl;
  final bool showActions;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLanguage;
  final VoidCallback onStartAudioCall;
  final VoidCallback onStartVideoCall;

  const ChatScreenAppBar({
    super.key,
    required this.title,
    required this.avatarUrl,
    this.showActions = true,
    required this.onBack,
    required this.onOpenProfile,
    required this.onOpenLanguage,
    required this.onStartAudioCall,
    required this.onStartVideoCall,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
          child: GestureDetector(
            onTap: onBack,
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
                size: 20,
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: onOpenProfile,
        child: Row(
          children: [
            if (avatarUrl != null && avatarUrl!.isNotEmpty)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  ApiConstants.buildImageUrl(avatarUrl),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F0F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Color(0xFF871DAD)),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (showActions) ...[
          _ActionIcon(icon: Icons.translate, onTap: onOpenLanguage),
          const SizedBox(width: 4),
          _ActionIcon(icon: Icons.phone_outlined, onTap: onStartAudioCall),
          const SizedBox(width: 4),
          _ActionIcon(icon: Icons.videocam_outlined, onTap: onStartVideoCall),
          const SizedBox(width: 20),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF871DAD),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
