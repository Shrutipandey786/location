import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ptt_button.dart';

class PushToTalkScreen extends StatefulWidget {
  final PeerUser? selectedPeer;

  const PushToTalkScreen({
    super.key,
    this.selectedPeer,
  });

  @override
  State<PushToTalkScreen> createState() => _PushToTalkScreenState();
}

class _PushToTalkScreenState extends State<PushToTalkScreen> {
  static final Set<String> _deletedPttMessageIds = {};

  final AuthApiService _apiService = AuthApiService();
  final WebSocketService _webSocketService = WebSocketService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<PeerUser> _peers = [];
  PeerUser? _activeChannelPeer;
  List<ChatMessage> _voiceStreamMessages = [];

  bool _isLoading = true;
  bool _isLoadingStream = false;
  String? _errorMessage;

  bool _isChannelBroadcasting = false;
  bool _isTransmitting = false;
  bool _isUploading = false;
  bool _isPlayingAudio = false;
  String? _playingAudioId;
  String? _currentUserId;

  Timer? _timer;
  int _recordedSeconds = 0;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadPeersFromBackend();
    _setupWebSocket();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _playingAudioId = null;
        });
      }
    });
  }

  void _setupWebSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user != null && user.id != null) {
        _currentUserId = user.id.toString();
        _webSocketService.connect(_currentUserId!);
        _webSocketService.addMessageListener(_currentUserId!, _onWebSocketMessageReceived);
      }
    });
  }

  void _onWebSocketMessageReceived(Map<String, dynamic> json) {
    if (!mounted || _currentUserId == null) return;

    final senderIdStr = json['senderId']?.toString() ?? '';
    final recipientIdStr = json['recipientId']?.toString() ?? '';

    if (_activeChannelPeer != null &&
        (senderIdStr == _activeChannelPeer!.id || recipientIdStr == _activeChannelPeer!.id)) {
      final newMsg = ChatMessage.fromJson(json, _currentUserId!);
      if (newMsg.type == MessageType.pttVoice) {
        setState(() {
          final existingIndex = _voiceStreamMessages.indexWhere((m) => m.id == newMsg.id && newMsg.id.isNotEmpty);
          if (existingIndex == -1) {
            _voiceStreamMessages.add(newMsg);
          } else {
            _voiceStreamMessages[existingIndex] = newMsg;
          }
        });

        if (_isChannelBroadcasting && senderIdStr != _currentUserId && newMsg.audioUrl != null) {
          _playAudioMessage(newMsg);
        }
      }
    }
  }

  @override
  void dispose() {
    if (_currentUserId != null) {
      _webSocketService.removeMessageListener(_currentUserId!, _onWebSocketMessageReceived);
    }
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPeersFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getConversations();
      if (response.data != null && response.data is List) {
        final listData = response.data as List<dynamic>;
        final summaries = listData
            .map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>))
            .where((s) => !DeletionStorageService().isPeerCleared(s.peerId))
            .toList();

        _peers = summaries.map((s) => s.toPeerUser()).toList();
      } else {
        _peers = [];
      }

      if (_peers.isNotEmpty) {
        if (widget.selectedPeer != null) {
          final matched = _peers.firstWhere(
            (p) => p.id == widget.selectedPeer!.id,
            orElse: () => _peers.first,
          );
          _activeChannelPeer = matched;
        } else {
          _activeChannelPeer = _peers.first;
        }
        await _loadChannelStream(_activeChannelPeer!.id);
      }

      setState(() {
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : (e.message ?? "Failed to load channel participants.");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadChannelStream(String peerId) async {
    setState(() {
      _isLoadingStream = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      _currentUserId = authProvider.currentUser?.id?.toString() ?? '';

      final response = await _apiService.getConversationDetail(peerId);
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final msgsJson = data['messages'] as List<dynamic>? ?? [];

        final allMsgs = msgsJson
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>, _currentUserId!))
            .toList();

        setState(() {
          _voiceStreamMessages = allMsgs.where((m) => m.type == MessageType.pttVoice && !DeletionStorageService().isMessageDeleted(m.id)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading PTT stream: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStream = false;
        });
      }
    }
  }

  Future<void> _playAudioMessage(ChatMessage message) async {
    final audioPath = message.audioUrl;
    if (audioPath == null || audioPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No audio file available for this voice memo.")),
      );
      return;
    }

    if (_isPlayingAudio && _playingAudioId == message.id) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingAudio = false;
        _playingAudioId = null;
      });
      return;
    }

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
          _isPlayingAudio = true;
          _playingAudioId = message.id;
        });
      }
    } catch (e) {
      debugPrint("PTT Playback error: $e");
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _playingAudioId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Playback error: $e")),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_activeChannelPeer == null) return;

    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/ptt_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        _recordingPath = path;
        _recordedSeconds = 0;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() {
              _recordedSeconds++;
            });
          }
        });

        setState(() {
          _isTransmitting = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied")),
          );
        }
      }
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _timer?.cancel();
    _timer = null;

    if (!_isTransmitting && _recordingPath == null) return;

    setState(() {
      _isTransmitting = false;
    });

    try {
      final recordedPath = await _audioRecorder.stop();
      final duration = _recordedSeconds > 0 ? _recordedSeconds : 1;

      final path = recordedPath ?? _recordingPath;
      if (path != null && _activeChannelPeer != null) {
        setState(() {
          _isUploading = true;
        });

        double? lat;
        double? lng;
        String? address;

        try {
          if (await Geolocator.isLocationServiceEnabled()) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
              Position position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
              );
              lat = position.latitude;
              lng = position.longitude;
              address = "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
            }
          }
        } catch (e) {
          debugPrint("GPS location check error: $e");
        }

        final response = await _apiService.sendVoiceMessage(
          _activeChannelPeer!.id,
          path,
          duration,
          latitude: lat,
          longitude: lng,
          address: address,
        );

        if (response.data != null && response.data is Map<String, dynamic>) {
          final newMsg = ChatMessage.fromJson(response.data as Map<String, dynamic>, _currentUserId ?? '');
          setState(() {
            _voiceStreamMessages.add(newMsg);
          });
        } else {
          _loadChannelStream(_activeChannelPeer!.id);
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Voice memo (${duration}s) transmitted to ${_activeChannelPeer!.name}"),
              backgroundColor: AppTheme.statusGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("PTT voice transmit error: $e");
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to transmit voice memo: $e"),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    } finally {
      _recordingPath = null;
    }
  }

  Future<void> _confirmDeleteVoiceStream(ChatMessage msg) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Voice Memo"),
        content: const Text("Are you sure you want to delete this voice memo stream?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (msg.id.isNotEmpty) {
        await DeletionStorageService().addDeletedMessage(msg.id);
      }
      try {
        await _apiService.deleteMessage(_activeChannelPeer?.id ?? '', msg.id);
      } catch (e) {
        debugPrint("API delete voice memo error: $e");
      }
      setState(() {
        _voiceStreamMessages.removeWhere((m) => m.id == msg.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voice memo stream deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildVoiceStreamCard(ChatMessage msg, bool isDark) {
    final bool isPlayingThis = _isPlayingAudio && _playingAudioId == msg.id;
    final bool isMe = msg.senderId == "user_me" || msg.senderId == _currentUserId;

    return GestureDetector(
      onLongPress: () => _confirmDeleteVoiceStream(msg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primaryIndigo
              : (isDark ? AppTheme.darkSurface : Colors.indigo.shade50),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              GestureDetector(
                onTap: () => _playAudioMessage(msg),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlayingThis ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.primaryIndigo,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voice memo stream (${(msg.pttDurationSeconds ?? 3).toString().padLeft(2, '0')}s)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isMe ? Colors.white : (isDark ? Colors.white : AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "${msg.deviceModel} • ${msg.batteryLevel}% • ${msg.formattedTime}",
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isMe)
                          const Icon(Icons.done_all, size: 12, color: Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AudioWaveformPainter(
                values: msg.audioWaveform ?? [0.4, 0.8, 0.5, 0.9, 0.3, 0.7, 0.4, 0.6],
                color: isMe ? Colors.white : AppTheme.primaryIndigo,
              ),
              const SizedBox(width: 8),
              Text(
                "${msg.pttDurationSeconds ?? 3}s",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : AppTheme.primaryIndigo,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final myUser = authProvider.currentUser;
    final String myUserName = myUser?.name.isNotEmpty == true ? myUser!.name : "User A";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Push to Talk"),
        actions: [
          IconButton(
            icon: Icon(
              _isChannelBroadcasting ? Icons.volume_up : Icons.volume_off,
              color: AppTheme.primaryIndigo,
            ),
            onPressed: () {
              setState(() => _isChannelBroadcasting = !_isChannelBroadcasting);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isChannelBroadcasting ? "Radio Speaker Active" : "Radio Speaker Muted"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryIndigo),
              )
            : (_errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.statusRed),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryIndigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loadPeersFromBackend,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text("Retry", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : (_peers.isEmpty
                    ? const Center(
                        child: Text(
                          "No peer users found for PTT Intercom.",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : Column(
                        children: [
                          // Channel Selector Card
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 2,
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.radio, color: AppTheme.primaryIndigo, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "PTT Intercom Channel",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                _activeChannelPeer?.name ?? "Select Receiver",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.statusGreen.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "CH 04",
                                            style: TextStyle(
                                              color: AppTheme.statusGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Peer Selector Chips
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: _peers.map((peer) {
                                          final isSel = peer.id == _activeChannelPeer!.id;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: ChoiceChip(
                                              label: Text(peer.name),
                                              selected: isSel,
                                              onSelected: (_) {
                                                setState(() => _activeChannelPeer = peer);
                                                _loadChannelStream(peer.id);
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Live PTT Voice Stream Feed from Backend
                          Expanded(
                            child: _isLoadingStream
                                ? const Center(
                                    child: CircularProgressIndicator(color: AppTheme.primaryIndigo, strokeWidth: 2),
                                  )
                                : (_voiceStreamMessages.isEmpty
                                    ? Center(
                                        child: Text(
                                          "No live voice stream recordings for CH 04 yet.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        itemCount: _voiceStreamMessages.length,
                                        itemBuilder: (context, index) {
                                          final msg = _voiceStreamMessages[index];
                                          return _buildVoiceStreamCard(msg, isDark);
                                        },
                                      )),
                          ),

                          const SizedBox(height: 8),

                          // Voice Status Banner & Soundwave
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isTransmitting
                                        ? AppTheme.statusRed.withOpacity(0.15)
                                        : (_isUploading
                                            ? AppTheme.accentCyan.withOpacity(0.15)
                                            : AppTheme.primaryIndigo.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isTransmitting
                                          ? AppTheme.statusRed
                                          : (_isUploading ? AppTheme.accentCyan : AppTheme.primaryIndigo.withOpacity(0.3)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _isTransmitting
                                              ? AppTheme.statusRed
                                              : (_isUploading ? AppTheme.accentCyan : AppTheme.statusGreen),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isTransmitting
                                            ? "RECORDING & TRANSMITTING (${_recordedSeconds}s)"
                                            : (_isUploading
                                                ? "UPLOADING VOICE MEMO..."
                                                : "READY TO BROADCAST TO ${_activeChannelPeer?.name.toUpperCase()}"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _isTransmitting
                                              ? AppTheme.statusRed
                                              : (_isUploading ? AppTheme.accentCyan : AppTheme.primaryIndigo),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Equalizer Waveform Animation
                                AudioWaveformPainter(
                                  values: _isTransmitting
                                      ? [0.8, 0.4, 0.9, 0.2, 0.7, 1.0, 0.5, 0.8, 0.3, 0.9, 0.6, 0.8, 0.4]
                                      : [0.1, 0.2, 0.1, 0.2, 0.1, 0.2, 0.1, 0.2, 0.1, 0.2],
                                  color: _isTransmitting ? AppTheme.statusRed : AppTheme.primaryViolet,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Main Push-To-Talk Button
                          PushToTalkButton(
                            onStateChanged: (talking) {
                              if (talking) {
                                _startRecording();
                              } else {
                                _stopRecordingAndSend();
                              }
                            },
                          ),

                          const SizedBox(height: 12),
                          Text(
                            "Press & Hold button to stream live voice memo\nGPS Lat/Long tagged to voice frame automatically",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),

                          const SizedBox(height: 8),

                          // Channel Participants Footer Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, color: AppTheme.primaryIndigo, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Channel Participants: $myUserName (You), ${_activeChannelPeer?.name ?? 'Receiver'}",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))),
      ),
    );
  }
}