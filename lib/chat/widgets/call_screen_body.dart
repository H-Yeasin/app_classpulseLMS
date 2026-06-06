import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

class CallScreenBody extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String statusLabel;
  final bool isLoading;
  final bool isMuted;
  final bool isVideoCall;
  final bool hasRemoteVideo;
  final bool hasLocalVideo;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final VoidCallback onToggleMute;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndCall;

  const CallScreenBody({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.statusLabel,
    required this.isLoading,
    required this.isMuted,
    required this.isVideoCall,
    required this.hasRemoteVideo,
    required this.hasLocalVideo,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.onToggleMute,
    required this.onSwitchCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: hasRemoteVideo
                  ? RTCVideoView(
                      remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _CallFallbackBody(
                      imageUrl: imageUrl,
                      isVideoCall: isVideoCall,
                    ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const _CallHeader(),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                  const Spacer(),
                  if (hasLocalVideo)
                    _LocalVideoPreview(localRenderer: localRenderer),
                  _CallControls(
                    isMuted: isMuted,
                    isVideoCall: isVideoCall,
                    onToggleMute: onToggleMute,
                    onSwitchCamera: onSwitchCamera,
                    onEndCall: onEndCall,
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

class _CallHeader extends StatelessWidget {
  const _CallHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline, color: Colors.white70, size: 14),
        SizedBox(width: 8),
        Text(
          'Secure connection',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _LocalVideoPreview extends StatelessWidget {
  final RTCVideoRenderer localRenderer;

  const _LocalVideoPreview({required this.localRenderer});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 110,
        height: 160,
        margin: const EdgeInsets.only(right: 24, bottom: 20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: RTCVideoView(
          localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool isMuted;
  final bool isVideoCall;
  final VoidCallback onToggleMute;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndCall;

  const _CallControls({
    required this.isMuted,
    required this.isVideoCall,
    required this.onToggleMute,
    required this.onSwitchCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            onTap: onToggleMute,
          ),
          if (isVideoCall)
            _CallControlButton(
              icon: Icons.flip_camera_android_outlined,
              onTap: onSwitchCamera,
            ),
          GestureDetector(
            onTap: onEndCall,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEA4335),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CallControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF444444),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _CallFallbackBody extends StatelessWidget {
  final String imageUrl;
  final bool isVideoCall;

  const _CallFallbackBody({required this.imageUrl, required this.isVideoCall});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 90,
            backgroundColor: Colors.white10,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(ApiConstants.buildImageUrl(imageUrl))
                : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white70, size: 72)
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            isVideoCall ? 'Waiting for video...' : 'Audio call in progress',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
