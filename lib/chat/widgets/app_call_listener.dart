import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/providers/call_provider.dart';
import 'package:opalmer_education/chat/screens/incoming_call_screen.dart';
import 'package:opalmer_education/core/navigation/app_navigator.dart';

class AppCallListener extends ConsumerStatefulWidget {
  final Widget child;

  const AppCallListener({super.key, required this.child});

  @override
  ConsumerState<AppCallListener> createState() => _AppCallListenerState();
}

class _AppCallListenerState extends ConsumerState<AppCallListener> {
  bool _incomingRouteOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(callNotifierProvider);

    ref.listen(callNotifierProvider, (previous, next) {
      final incomingCall = next.incomingCall;
      if (incomingCall == null || _incomingRouteOpen) return;

      _incomingRouteOpen = true;
      appNavigatorKey.currentState
          ?.push(
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(call: incomingCall),
            ),
          )
          .whenComplete(() {
            _incomingRouteOpen = false;
          });
    });

    return widget.child;
  }
}
