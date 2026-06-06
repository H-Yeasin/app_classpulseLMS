import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

class CallHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final String? currentUserId;

  const CallHistoryList({
    super.key,
    required this.logs,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('No call history found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: logs.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
      itemBuilder: (context, index) {
        final log = logs[index];
        final caller = _asMap(log['callerId']);
        final receiver = _asMap(log['receiverId']);
        final receiverId = _readId(receiver);
        final isIncoming = currentUserId != null && receiverId == currentUserId;
        final participant = isIncoming ? caller : receiver;
        final fallbackParticipant = isIncoming ? receiver : caller;

        return _CallHistoryItem(
          name:
              _readName(participant) ??
              _readName(fallbackParticipant) ??
              'Unknown',
          date: _formatDate(log['startedAt']?.toString()),
          isIncoming: isIncoming,
          imageUrl:
              _readAvatarUrl(participant) ??
              _readAvatarUrl(fallbackParticipant) ??
              '',
          status: _formatStatus(log['status']?.toString()),
        );
      },
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _readId(Map<String, dynamic>? user) {
    final value = user?['id'] ?? user?['_id'];
    final id = value?.toString();
    return id == null || id.isEmpty ? null : id;
  }

  static String? _readName(Map<String, dynamic>? user) {
    final value = user?['username'] ?? user?['name'];
    final name = value?.toString().trim();
    return name == null || name.isEmpty ? null : name;
  }

  static String? _readAvatarUrl(Map<String, dynamic>? user) {
    final avatar = user?['avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    if (avatar is Map) {
      final url = avatar['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  static String _formatDate(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return 'Unknown date';

    final parsed = DateTime.tryParse(rawValue);
    if (parsed == null) return rawValue;

    final local = parsed.toLocal();
    final month = _monthLabel(local.month);
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} • $hour:$minute $period';
  }

  static String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static String _formatStatus(String? rawStatus) {
    final status = (rawStatus ?? 'ended').trim();
    if (status.isEmpty) return 'Ended';
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _CallHistoryItem extends StatelessWidget {
  final String name;
  final String date;
  final bool isIncoming;
  final String imageUrl;
  final String status;

  const _CallHistoryItem({
    required this.name,
    required this.date,
    required this.isIncoming,
    required this.imageUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            CircleAvatar(
                radius: 28,
                backgroundImage:
                    NetworkImage(ApiConstants.buildImageUrl(imageUrl)))
          else
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F0F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF871DAD)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isIncoming ? Icons.south_west : Icons.north_east,
                      size: 14,
                      color: status == 'missed'
                          ? const Color(0xFFEA4335)
                          : const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$date • $status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // const SizedBox(width: 12),
          // Container(
          //   width: 40,
          //   height: 40,
          //   decoration: const BoxDecoration(
          //     color: Color(0xFF871DAD),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(Icons.phone, color: Colors.white, size: 18),
          // ),
        ],
      ),
    );
  }
}
