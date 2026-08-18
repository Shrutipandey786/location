import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/auth_api_service.dart';
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
  final AuthApiService _apiService = AuthApiService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  List<PeerUser> _peers = [];
  PeerUser? _activeChannelPeer;

  bool _isLoading = true;
  String? _errorMessage;

  bool _isChannelBroadcasting = false;
  bool _isTransmitting = false;
  bool _isUploading = false;

  Timer? _timer;
  int _recordedSeconds = 0;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _loadPeersFromBackend();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
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

  Future<void> _startRecording() async {
    if (_activeChannelPeer == null) return;

    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/ptt_${DateTime.now().millisecondsSinceEpoch}.m4a';

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

        await _apiService.sendVoiceMessage(
          _activeChannelPeer!.id,
          path,
          duration,
          latitude: lat,
          longitude: lng,
          address: address,
        );

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
                                              onSelected: (_) => setState(() => _activeChannelPeer = peer),
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

                          const Spacer(),

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
                                const SizedBox(height: 24),

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

                          const Spacer(),

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

                          const SizedBox(height: 16),
                          Text(
                            "Press & Hold button to stream live voice memo\nGPS Lat/Long tagged to voice frame automatically",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),

                          const Spacer(),

                          // Channel Participants Footer Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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