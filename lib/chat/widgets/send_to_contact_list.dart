import 'package:flutter/material.dart';

import 'package:opalmer_education/core/constants/api_constants.dart';

class SendToContactList extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final bool isMultiSelect;

  const SendToContactList({
    super.key,
    required this.contacts,
    required this.selectedIds,
    required this.onToggleSelection,
    this.isMultiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    final teachers = contacts
        .where((c) => c['type'] == 'teacher' || c['role'] == 'administrator')
        .toList();
    final students = contacts.where((c) => c['type'] == 'student').toList();
    final parents = contacts.where((c) => c['type'] == 'parent').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (teachers.isNotEmpty) ...[
          const _ContactSectionHeader(title: 'Teachers'),
          ...teachers.map(
            (contact) => _ContactTile(
              contact: contact,
              isSelected: selectedIds.contains(contact['id']?.toString() ?? ''),
              isMultiSelect: isMultiSelect,
              onTap: () => onToggleSelection(contact['id']?.toString() ?? ''),
            ),
          ),
        ],
        if (students.isNotEmpty) ...[
          const _ContactSectionHeader(title: 'Students'),
          ...students.map(
            (contact) => _ContactTile(
              contact: contact,
              isSelected: selectedIds.contains(contact['id']?.toString() ?? ''),
              isMultiSelect: isMultiSelect,
              onTap: () => onToggleSelection(contact['id']?.toString() ?? ''),
            ),
          ),
        ],
        if (parents.isNotEmpty) ...[
          const _ContactSectionHeader(title: 'Parents'),
          ...parents.map(
            (contact) => _ContactTile(
              contact: contact,
              isSelected: selectedIds.contains(contact['id']?.toString() ?? ''),
              isMultiSelect: isMultiSelect,
              onTap: () => onToggleSelection(contact['id']?.toString() ?? ''),
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ContactSectionHeader extends StatelessWidget {
  final String title;

  const _ContactSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF871DAD),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isSelected,
    this.isMultiSelect = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = contact['username'] ?? contact['name'] ?? 'User';
    final rawAvatar = contact['avatar'] ?? contact['imageUrl'];
    String? avatarUrl;
    if (rawAvatar is String) {
      avatarUrl = rawAvatar;
    } else if (rawAvatar is Map) {
      avatarUrl = rawAvatar['url']?.toString();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 20),
        color: Colors.transparent,
        child: Row(
          children: [
            Stack(
              children: [
                if (avatarUrl != null &&
                    avatarUrl.isNotEmpty &&
                    !avatarUrl.toLowerCase().endsWith('.pdf'))
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: NetworkImage(
                        ApiConstants.buildImageUrl(avatarUrl)),
                    onBackgroundImageError: (error, stackTrace) {},
                  )
                else
                  const _PlaceholderAvatar(),
                if (isMultiSelect && isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF871DAD).withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (contact['subtitle'] != null)
                    Text(
                      contact['subtitle'].toString(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      (contact['type'] ?? contact['role'] ?? 'USER')
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF871DAD).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Color(0xFF871DAD), size: 28),
    );
  }
}
