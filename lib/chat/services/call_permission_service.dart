import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPermissionService {
  static Future<bool> ensureCallPermissions(
    BuildContext context, {
    required CallMediaType callType,
  }) async {
    final microphoneStatus = await Permission.microphone.request();
    PermissionStatus? cameraStatus;

    if (callType == CallMediaType.video) {
      cameraStatus = await Permission.camera.request();
    }

    final microphoneGranted = microphoneStatus.isGranted;
    final cameraGranted = callType == CallMediaType.audio
        ? true
        : (cameraStatus?.isGranted ?? false);

    if (microphoneGranted && cameraGranted) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final blockedStatuses = <PermissionStatus>[microphoneStatus, ?cameraStatus];
    final requiresSettings = blockedStatuses.any(
      (status) => status.isPermanentlyDenied || status.isRestricted,
    );

    final permissionLabel = callType == CallMediaType.video
        ? 'camera and microphone'
        : 'microphone';

    if (requiresSettings) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Permission needed'),
            content: Text(
              'Please allow $permissionLabel access in Settings to use calling.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please allow $permissionLabel access to continue with the call.',
        ),
      ),
    );
    return false;
  }
}
