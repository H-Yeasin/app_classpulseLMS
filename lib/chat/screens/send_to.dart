import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/providers/chat_provider.dart';
import 'package:opalmer_education/chat/services/chat_api_service.dart';
import 'package:opalmer_education/chat/widgets/chat_simple_app_bar.dart';
import 'package:opalmer_education/chat/widgets/send_to_action_button.dart';
import 'package:opalmer_education/chat/widgets/send_to_contact_list.dart';
import 'package:opalmer_education/chat/widgets/send_to_search_bar.dart';
import 'package:opalmer_education/chat/widgets/group_details_bottom_sheet.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';

import '../models/chat_role.dart';
import 'chat_screen.dart';

class SendToScreen extends ConsumerStatefulWidget {
  final ChatRole role;

  const SendToScreen({super.key, this.role = ChatRole.teacher});

  @override
  ConsumerState<SendToScreen> createState() => _SendToScreenState();
}

class _SendToScreenState extends ConsumerState<SendToScreen> {
  final ChatApiService _apiService = ChatApiService();
  final Set<String> _selectedIds = {};

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  bool get _isTeacher => widget.role == ChatRole.teacher;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _apiService.getContacts();
      if (!mounted) return;

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleContactTap(String id) {
    if (id.isEmpty) return;

    if (!_isTeacher) {
      // Parents/Students immediately start chat with selected contact
      _selectedIds.clear();
      _selectedIds.add(id);
      _createOrOpenRoom();
      return;
    }

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _createOrOpenRoom() async {
    try {
      final user = ref.read(authStateProvider);
      if (user == null) return;

      String? groupName;
      File? groupAvatar;

      if (_isTeacher && _selectedIds.length > 1) {
        final result = await GroupDetailsBottomSheet.show(context);
        if (result == null) return; // User cancelled
        groupName = result.name;
        groupAvatar = result.avatar;
      }

      final room = await _apiService.createRoom(
        _selectedIds.toList(),
        user.id,
        name: groupName,
        avatar: groupAvatar,
      );
      
      if (!mounted) return;

      if (room != null) {
        ref.read(chatNotifierProvider.notifier).addRoom(room);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(session: room, role: widget.role),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to create chat room. You may not have permission.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      var message = error.toString();
      if (message.contains('403')) {
        message =
            'Access denied. You can only message students in your classes.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ChatSimpleAppBar(title: 'Send To'),
      body: Column(
        children: [
          const SendToSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                ? const Center(child: Text('No contacts found'))
                : SendToContactList(
                    contacts: _contacts,
                    selectedIds: _selectedIds,
                    isMultiSelect: _isTeacher,
                    onToggleSelection: _handleContactTap,
                  ),
          ),
          if (_isTeacher)
            SendToActionButton(
              selectedCount: _selectedIds.length,
              label: _selectedIds.length > 1 
                  ? 'CREATE GROUP (${_selectedIds.length})' 
                  : 'START CHAT',
              onPressed: _selectedIds.isEmpty ? null : _createOrOpenRoom,
            ),
        ],
      ),
    );
  }
}
