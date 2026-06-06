import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/services/chat_api_service.dart';
import 'package:opalmer_education/chat/widgets/call_history_list.dart';
import 'package:opalmer_education/chat/widgets/chat_simple_app_bar.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final ChatApiService _apiService = ChatApiService();

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _apiService.getCallLogs();
      if (!mounted) return;

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ChatSimpleAppBar(title: 'Call History'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CallHistoryList(logs: _logs, currentUserId: currentUser?.id),
    );
  }
}
