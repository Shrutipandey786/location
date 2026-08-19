import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import 'ptt_button.dart';

class LocationMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onDelete;

  const LocationMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
  });

  @override
  State<LocationMessageBubble> createState() => _LocationMessageBubbleState();
}

class _LocationMessageBubbleState extends State<LocationMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AuthApiService _apiService = AuthApiService();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final audioPath = widget.message.audioUrl;
    if (audioPath == null || audioPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No audio file available for this voice memo.")),
      );
      return;
    }

    setState(() {
      _isLoadingAudio = true;
    });

    try {
      String fullUrl = audioPath;
      if (audioPath.startsWith("/")) {
        String baseUrl = await _apiService.getBaseUrl();
        if (baseUrl.endsWith("/api")) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 4);
        } else if (baseUrl.endsWith("/api/")) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 5);
        }
        fullUrl = "$baseUrl$audioPath";
      }

      await _audioPlayer.play(UrlSource(fullUrl));
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      debugPrint("Audio playback error: $e");
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Playback error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isMe
        ? AppTheme.primaryIndigo
        : (isDark ? AppTheme.darkSurface : Colors.white);

    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : AppTheme.textPrimary);

    final subTextColor = isMe
        ? Colors.white.withOpacity(0.85)
        : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),

          GestureDetector(
            onLongPress: widget.onDelete,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isMe
                  ? null
                  : Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderLight,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera Snapshot Image Preview
                if (message.cameraImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      message.cameraImageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.photo_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Voice Waveform Card with Real Data & Playback
                if (message.type == MessageType.pttVoice) ...[
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleAudioPlayback,
                        child: _isLoadingAudio
                            ? SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: isMe ? Colors.white : AppTheme.primaryIndigo,
                                ),
                              )
                            : Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: isMe ? Colors.white : AppTheme.primaryIndigo,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AudioWaveformPainter(
                          values: message.audioWaveform ?? [0.4, 0.8, 0.5, 0.9, 0.3, 0.7, 0.4, 0.6],
                          color: isMe ? Colors.white : AppTheme.primaryIndigo,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${message.pttDurationSeconds ?? 0}s",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Text Content
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Clean Location Tag
                if (message.location != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withOpacity(0.18)
                          : AppTheme.primaryIndigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: isMe ? Colors.amberAccent : AppTheme.primaryIndigo,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "GPS ${message.location!.formatCoordinates()}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : AppTheme.primaryIndigo,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Device & Timestamp Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${message.deviceModel} • ${message.batteryLevel}%",
                      style: TextStyle(
                        fontSize: 9,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: subTextColor,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all,
                        size: 13,
                        color: message.status == MessageStatus.read ? Colors.lightBlueAccent : subTextColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}