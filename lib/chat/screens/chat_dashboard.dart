import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/widgets/chat_session_slidable_item.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';

import '../models/chat_role.dart';
import '../models/chat_session_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_dashboard_header.dart';
import '../widgets/chat_dashboard_tabs.dart';
import '../widgets/chat_room_list.dart';
import 'chat_screen.dart';
import 'call_history.dart';
import 'send_to.dart';

class ChatDashboard extends ConsumerStatefulWidget {
  final int initialTab;
  final ChatRole role;

  const ChatDashboard({
    super.key,
    this.initialTab = 0,
    this.role = ChatRole.teacher,
  });

  @override
  ConsumerState<ChatDashboard> createState() => _ChatDashboardState();
}

class _ChatDashboardState extends ConsumerState<ChatDashboard> {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  late int _selectedTab;
  int? _openedIndex;
  bool _isLoadingTeachers = false;
  List<_ParentTeacherTarget> _teacherTargets = const [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    if (widget.role == ChatRole.parent) {
      _loadParentTeachers();
    }
  }

  void _handleSlide(int tab, int index) {
    final uniqueId = tab * 1000 + index;
    if (_openedIndex == uniqueId) return;

    setState(() {
      _openedIndex = uniqueId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider)?.id;
    final directRooms = _roomsForType(ChatSessionType.direct);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _DashboardContent(
            role: widget.role,
            selectedTab: _selectedTab,
            openedIndex: _openedIndex,
            onTabChanged: (index) => setState(() => _selectedTab = index),
            onSlide: _handleSlide,
            directRooms: directRooms,
            draftRooms: _roomsForType(ChatSessionType.draft),
            groupRooms: _roomsForType(ChatSessionType.group),
            teacherSessions: _teacherSessions(
              directRooms: directRooms,
              currentUserId: currentUserId,
            ),
            isLoadingTeachers: _isLoadingTeachers,
            onTeacherTap: (session) => _openTeacherChat(
              session: session,
              currentUserId: currentUserId,
            ),
          ),
          if (widget.role.canComposeNewChat)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'chat_fab_${widget.role.name}',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendToScreen(role: widget.role),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF871DAD),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
        ],
      ),
    );
  }

  List<ChatSessionModel> _roomsForType(ChatSessionType type) {
    final rooms = ref.watch(chatNotifierProvider).rooms;
    return rooms.where((room) => room.type == type).toList();
  }

  Future<void> _loadParentTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final user = ref.read(authStateProvider);
      final parentId = user?.id ?? await _parentIdFromStorage();
      if (parentId == null || parentId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _teacherTargets = const [];
          _isLoadingTeachers = false;
        });
        return;
      }

      final childrenResponse = await _apiClient.get(
        ApiConstants.childrenByParent(parentId),
      );
      final List relations =
          (childrenResponse.data is Map && childrenResponse.data['data'] is Map)
          ? (childrenResponse.data['data']['children'] as List? ?? const [])
          : const [];

      final childIds = relations
          .map((relation) => relation['childId'])
          .whereType<Map>()
          .map((child) => (child['_id'] ?? child['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      final teachers = <String, _ParentTeacherTarget>{};

      for (final childId in childIds) {
        final classesResponse = await _apiClient.get(
          ApiConstants.classesByStudent(childId),
        );
        final List classes =
            (classesResponse.data is Map && classesResponse.data['data'] is Map)
            ? (classesResponse.data['data']['classes'] as List? ?? const [])
            : const [];

        for (final rawClass in classes.whereType<Map>()) {
          final classMap = Map<String, dynamic>.from(rawClass);
          final teacherMap = classMap['teacherId'] is Map
              ? Map<String, dynamic>.from(classMap['teacherId'])
              : null;
          final teacherId = (teacherMap?['_id'] ?? teacherMap?['id'] ?? '')
              .toString();
          if (teacherId.isEmpty) continue;

          final teacher = teachers.putIfAbsent(
            teacherId,
            () => _ParentTeacherTarget(
              teacherId: teacherId,
              teacherName: (teacherMap?['username'] ?? 'Teacher').toString(),
              teacherAvatarUrl: _readAvatarUrl(teacherMap),
              subjects: <String>{},
            ),
          );

          final subject = (classMap['subject'] ?? '').toString().trim();
          if (subject.isNotEmpty) {
            teacher.subjects.add(subject);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _teacherTargets = teachers.values.toList();
        _isLoadingTeachers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _teacherTargets = const [];
        _isLoadingTeachers = false;
      });
    }
  }

  Future<String?> _parentIdFromStorage() async {
    final rawUserData = await _storage.getUserData();
    if (rawUserData == null) return null;

    final decoded = jsonDecode(rawUserData);
    if (decoded is! Map<String, dynamic>) return null;
    return (decoded['id'] ?? decoded['_id'])?.toString();
  }

  String _readAvatarUrl(Map<String, dynamic>? userData) {
    final avatar = userData?['avatar'];
    if (avatar is String && avatar.isNotEmpty) {
      return avatar;
    }
    if (avatar is Map) {
      final url = avatar['url']?.toString() ?? '';
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  List<ChatSessionModel> _teacherSessions({
    required List<ChatSessionModel> directRooms,
    required String? currentUserId,
  }) {
    if (widget.role != ChatRole.parent) {
      return const [];
    }

    return _teacherTargets.map((teacher) {
      final existingRoom = directRooms.cast<ChatSessionModel?>().firstWhere(
        (room) =>
            room != null && room.participantIds.contains(teacher.teacherId),
        orElse: () => null,
      );

      if (existingRoom != null) {
        return existingRoom.copyWith(
          title: existingRoom.title.isNotEmpty
              ? existingRoom.title
              : teacher.teacherName,
          avatarUrl: (existingRoom.avatarUrl?.isNotEmpty ?? false)
              ? existingRoom.avatarUrl
              : teacher.teacherAvatarUrl,
          subtitle: existingRoom.subtitle.isNotEmpty
              ? existingRoom.subtitle
              : teacher.subjectSummary,
        );
      }

      return ChatSessionModel(
        id: 'teacher-${teacher.teacherId}',
        type: ChatSessionType.direct,
        title: teacher.teacherName,
        subtitle: teacher.subjectSummary,
        updatedAt: DateTime.now(),
        participantIds: [
          if (currentUserId != null && currentUserId.isNotEmpty) currentUserId,
          teacher.teacherId,
        ],
        avatarUrl: teacher.teacherAvatarUrl.isEmpty
            ? null
            : teacher.teacherAvatarUrl,
      );
    }).toList();
  }

  void _openTeacherChat({
    required ChatSessionModel session,
    required String? currentUserId,
  }) async {
    final peerId = session.participantIds.firstWhere(
      (id) => id != currentUserId && !id.startsWith('teacher-'),
      orElse: () => '',
    );
    if (peerId.isEmpty || !mounted) return;

    final room = await ref
        .read(chatNotifierProvider.notifier)
        .getOrCreateDirectRoom(peerId);
    if (!mounted || room == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(session: room, role: widget.role),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final ChatRole role;
  final int selectedTab;
  final int? openedIndex;
  final ValueChanged<int> onTabChanged;
  final void Function(int tab, int index) onSlide;
  final List<ChatSessionModel> directRooms;
  final List<ChatSessionModel> draftRooms;
  final List<ChatSessionModel> groupRooms;
  final List<ChatSessionModel> teacherSessions;
  final bool isLoadingTeachers;
  final void Function(ChatSessionModel session) onTeacherTap;

  const _DashboardContent({
    required this.role,
    required this.selectedTab,
    required this.openedIndex,
    required this.onTabChanged,
    required this.onSlide,
    required this.directRooms,
    required this.draftRooms,
    required this.groupRooms,
    required this.teacherSessions,
    required this.isLoadingTeachers,
    required this.onTeacherTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider);

    return Column(
      children: [
        ChatDashboardHeader(
          onOpenCallHistory: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CallHistoryScreen(),
              ),
            );
          },
          onOpenNotifications: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ChatDashboardTabs(
          selectedTab: selectedTab,
          groupTabLabel: role.groupTabLabel,
          onChanged: onTabChanged,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: chatState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatState.error != null
              ? Center(
                  child: Text(
                    chatState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : IndexedStack(
                  index: selectedTab,
                  children: [
                    ChatRoomList(
                      sessions: directRooms,
                      tab: 0,
                      role: role,
                      openedIndex: openedIndex,
                      onSlide: onSlide,
                    ),
                    ChatRoomList(
                      sessions: draftRooms,
                      tab: 1,
                      role: role,
                      openedIndex: openedIndex,
                      onSlide: onSlide,
                    ),
                    if (role == ChatRole.parent && isLoadingTeachers)
                      const Center(child: CircularProgressIndicator())
                    else
                      ChatRoomList(
                        sessions: role == ChatRole.parent
                            ? teacherSessions
                            : groupRooms,
                        tab: 2,
                        role: role,
                        openedIndex: openedIndex,
                        onSlide: onSlide,
                        emptyLabel: role == ChatRole.parent
                            ? 'No teachers found'
                            : null,
                        onSessionTap: role == ChatRole.parent
                            ? onTeacherTap
                            : null,
                        actionsBuilder: role == ChatRole.parent
                            ? (_) => <ChatSessionAction>[]
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ParentTeacherTarget {
  final String teacherId;
  final String teacherName;
  final String teacherAvatarUrl;
  final Set<String> subjects;

  const _ParentTeacherTarget({
    required this.teacherId,
    required this.teacherName,
    required this.teacherAvatarUrl,
    required this.subjects,
  });

  String get subjectSummary {
    if (subjects.isEmpty) {
      return 'Tap to start chatting';
    }
    return subjects.join(', ');
  }
}
