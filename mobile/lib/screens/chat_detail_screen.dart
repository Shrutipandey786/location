import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_message_bubble.dart';
import 'live_camera_screen.dart';
import 'live_location_map_screen.dart';
import 'push_to_talk_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  static final Set<String> clearedPeerIds = {};
  static final Set<String> deletedMessageIds = {};

  final PeerUser peer;

  const ChatDetailScreen({
    super.key,
    required this.peer,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {

  final AuthApiService _apiService = AuthApiService();
  final WebSocketService _webSocketService = WebSocketService();
  late PeerUser _currentPeer;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPeer = widget.peer;
    _loadConversation();
    _setupWebSocket();
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

    if (senderIdStr == _currentPeer.id || recipientIdStr == _currentPeer.id) {
      final newMsg = ChatMessage.fromJson(json, _currentUserId!);
      setState(() {
        final existingIndex = _messages.indexWhere((m) => m.id == newMsg.id && newMsg.id.isNotEmpty);
        if (existingIndex == -1) {
          _messages.add(newMsg);
        } else {
          _messages[existingIndex] = newMsg;
        }
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    if (_currentUserId != null) {
      _webSocketService.removeMessageListener(_currentUserId!, _onWebSocketMessageReceived);
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      _currentUserId = authProvider.currentUser?.id?.toString() ?? '';

      final response = await _apiService.getConversationDetail(_currentPeer.id);
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['peer'] != null && data['peer'] is Map<String, dynamic>) {
          final peerJson = data['peer'] as Map<String, dynamic>;
          final lat = peerJson['latitude'] != null ? (peerJson['latitude'] as num).toDouble() : _currentPeer.location.latitude;
          final lng = peerJson['longitude'] != null ? (peerJson['longitude'] as num).toDouble() : _currentPeer.location.longitude;

          _currentPeer = PeerUser(
            id: peerJson['peerId']?.toString() ?? _currentPeer.id,
            name: peerJson['peerName']?.toString() ?? _currentPeer.name,
            email: peerJson['peerEmail']?.toString() ?? _currentPeer.email,
            avatarInitials: peerJson['avatarInitials']?.toString() ?? _currentPeer.avatarInitials,
            isOnline: peerJson['isOnline'] == true,
            statusMessage: peerJson['statusMessage']?.toString() ?? _currentPeer.statusMessage,
            batteryLevel: peerJson['batteryLevel'] != null ? (peerJson['batteryLevel'] as num).toInt() : _currentPeer.batteryLevel,
            deviceModel: peerJson['deviceModel']?.toString() ?? _currentPeer.deviceModel,
            location: LocationPoint(
              latitude: lat,
              longitude: lng,
              address: peerJson['address']?.toString() ?? _currentPeer.location.address,
              timestamp: DateTime.now(),
            ),
            distanceKm: _currentPeer.distanceKm,
            lastSeen: DateTime.now(),
          );
        }

        if (DeletionStorageService().isPeerCleared(_currentPeer.id)) {
          _messages = [];
        } else {
          final msgsJson = data['messages'] as List<dynamic>? ?? [];
          _messages = msgsJson
              .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>, _currentUserId!))
              .where((m) => !DeletionStorageService().isMessageDeleted(m.id))
              .toList();
        }

        _apiService.markConversationAsRead(_currentPeer.id);
      }

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : (e.message ?? "Failed to load conversation.");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmDeleteMessage(ChatMessage msg) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message?"),
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
        await _apiService.deleteMessage(_currentPeer.id, msg.id);
      } catch (e) {
        debugPrint("API delete error: $e");
      }
      setState(() {
        _messages.removeWhere((m) => m.id == msg.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Message deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearConversation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Conversation"),
        content: const Text("Are you sure you want to clear all messages in this conversation?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DeletionStorageService().addClearedPeer(_currentPeer.id);
      try {
        await _apiService.clearConversationMessages(_currentPeer.id);
      } catch (e) {
        debugPrint("API clear error: $e");
      }
      try {
        if (mounted) {
          context.read<ConversationProvider>().fetchConversations();
        }
      } catch (_) {}
      setState(() {
        _messages.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conversation messages cleared"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage({
    String? customText,
    MessageType type = MessageType.text,
    String? cameraUrl,
    int? pttDuration,
    List<double>? pttWaveform,
  }) async {
    final text = customText ?? _inputController.text.trim();
    if (text.isEmpty && type == MessageType.text) return;

    if (customText == null) _inputController.clear();

    double lat = 28.6139;
    double lng = 77.2090;
    String address = 'Live Location Pin';

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

    try {
      Response response;

      if (type == MessageType.location) {
        response = await _apiService.sendLocationMessage(
          _currentPeer.id,
          lat,
          lng,
          address: address,
          text: text.isNotEmpty ? text : "Shared Current GPS Location Pin",
        );
      } else if (type == MessageType.camera || type == MessageType.pttVoice) {
        String mediaTypeStr = type == MessageType.camera ? "CAMERA" : "PTT_VOICE";
        response = await _apiService.sendMediaMessage(
          _currentPeer.id,
          mediaTypeStr,
          cameraImageUrl: cameraUrl,
          pttDurationSeconds: pttDuration,
          text: text,
        );
      } else {
        String typeStr = "TEXT";
        if (type == MessageType.statusPreset) typeStr = "STATUS_PRESET";
        if (type == MessageType.sosAlert) typeStr = "SOS_ALERT";

        response = await _apiService.sendMessage(_currentPeer.id, {
          'text': text,
          'type': typeStr,
          'latitude': lat,
          'longitude': lng,
          'address': address,
        });
      }

      if (response.data != null && response.data is Map<String, dynamic>) {
        final currentUserId = _currentUserId ?? '';
        final jsonMap = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
        jsonMap['latitude'] ??= lat;
        jsonMap['longitude'] ??= lng;
        jsonMap['address'] ??= address;

        final newMsg = ChatMessage.fromJson(jsonMap, currentUserId);
        setState(() {
          final existingIndex = _messages.indexWhere((m) => m.id == newMsg.id && newMsg.id.isNotEmpty);
          if (existingIndex == -1) {
            _messages.add(newMsg);
          } else {
            _messages[existingIndex] = newMsg;
          }
        });
        _scrollToBottom();
      } else {
        _loadConversation();
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Error sending message."),
          backgroundColor: AppTheme.statusRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.statusRed,
        ),
      );
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Attach Content", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachOption(
                      icon: Icons.location_on_rounded,
                      color: AppTheme.statusGreen,
                      label: "GPS Location",
                      onTap: () {
                        Navigator.pop(context);
                        _sendMessage(type: MessageType.location);
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.camera_alt_rounded,
                      color: AppTheme.primaryIndigo,
                      label: "Live Camera",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveCameraScreen(
                              onPhotoCaptured: (capturedPhoto) {
                                if (capturedPhoto.isNotEmpty) {
                                  _sendMessage(
                                    type: MessageType.camera,
                                    cameraUrl: capturedPhoto,
                                    customText: "Live Camera Snapshot",
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.mic_rounded,
                      color: AppTheme.primaryViolet,
                      label: "Push-To-Talk",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PushToTalkScreen(selectedPeer: _currentPeer),
                          ),
                        ).then((_) => _loadConversation());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final peer = _currentPeer;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
              child: Text(
                peer.avatarInitials,
                style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: peer.isOnline ? AppTheme.statusGreen : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      peer.isOnline ? "Online â€¢ Active Channel" : "Offline",
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Messages",
            onPressed: _loadConversation,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.primaryIndigo),
            tooltip: "Live Location Map",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveLocationMapScreen(peer: peer),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_outlined, color: AppTheme.primaryViolet),
            tooltip: "Push-To-Talk Intercom",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PushToTalkScreen(selectedPeer: peer),
                ),
              ).then((_) => _loadConversation());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearConversation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.statusRed, size: 20),
                    SizedBox(width: 8),
                    Text("Clear Messages", style: TextStyle(color: AppTheme.statusRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
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
                          onPressed: _loadConversation,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text("Retry", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.chat_bubble_outline, size: 40, color: AppTheme.textSecondary),
                                  SizedBox(height: 8),
                                  Text(
                                    "No messages in this conversation yet.\nSend a message or GPS location to start!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isMe = msg.senderId == "user_me" || (_currentUserId != null && msg.senderId == _currentUserId);
                                return LocationMessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  onDelete: () => _confirmDeleteMessage(msg),
                                );
                              },
                            ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryIndigo),
                            label: const Text("I'm here.", style: TextStyle(fontSize: 11)),
                            onPressed: () => _sendMessage(customText: "I'm here.", type: MessageType.statusPreset),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: const Icon(Icons.navigation_outlined, size: 14, color: AppTheme.primaryViolet),
                            label: const Text("En route", style: TextStyle(fontSize: 11)),
                            onPressed: () => _sendMessage(customText: "En route to your location.", type: MessageType.statusPreset),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: const Icon(Icons.location_city, size: 14, color: AppTheme.accentCyan),
                            label: const Text("Arrived at checkpoint", style: TextStyle(fontSize: 11)),
                            onPressed: () => _sendMessage(customText: "Arrived at checkpoint A.", type: MessageType.statusPreset),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryIndigo, size: 26),
                            onPressed: _showAttachmentSheet,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              decoration: InputDecoration(
                                hintText: "Type message or location tag...",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: isDark ? AppTheme.darkInput : Colors.grey.shade100,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _sendMessage(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryIndigo,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
    );
  }
}
