import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../providers/conversation_provider.dart';
import '../services/deletion_storage_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';

extension ConversationSummaryMapper on ConversationSummary {
  PeerUser toPeerUser() {
    return PeerUser(
      id: peerId,
      name: peerName,
      email: peerEmail,
      avatarInitials: avatarInitials,
      isOnline: isOnline,
      statusMessage: statusMessage,
      batteryLevel: batteryLevel,
      deviceModel: deviceModel,
      location: LocationPoint(
        latitude: latitude ?? 28.6139,
        longitude: longitude ?? 77.2090,
        address: address ?? "Current Checkpoint",
        timestamp: lastMessageTime ?? DateTime.now(),
      ),
      distanceKm: 1.2,
      lastSeen: lastMessageTime ?? DateTime.now(),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().fetchConversations();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<ConversationProvider>().fetchConversations();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              context.read<ConversationProvider>().fetchConversations();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<ConversationProvider>().searchConversations(val);
              },
              decoration: InputDecoration(
                hintText: "Search messages or peers...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ConversationProvider>().fetchConversations();
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Conversations Content
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.conversations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryIndigo),
                  );
                }

                if (provider.errorMessage != null && provider.conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 50, color: AppTheme.statusRed),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryIndigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => provider.fetchConversations(),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text("Retry", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.conversations.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchConversations(),
                    color: AppTheme.primaryIndigo,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  provider.searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  provider.searchQuery.isNotEmpty
                                      ? "No conversations matching '${provider.searchQuery}'"
                                      : "No active conversations found",
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchConversations(),
                  color: AppTheme.primaryIndigo,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, index) {
                      final item = provider.conversations[index];

                      IconData msgIcon;
                      if (item.lastMessageType == 'LOCATION') {
                        msgIcon = Icons.location_on;
                      } else if (item.lastMessageType == 'CAMERA') {
                        msgIcon = Icons.camera_alt;
                      } else if (item.lastMessageType == 'PTT_VOICE') {
                        msgIcon = Icons.mic;
                      } else if (item.lastMessageType == 'SOS_ALERT') {
                        msgIcon = Icons.warning_amber_rounded;
                      } else {
                        msgIcon = Icons.chat_bubble_outline;
                      }

                      final isCleared = DeletionStorageService().isPeerCleared(item.peerId);
                      final displayLastMsg = isCleared ? "No messages" : (item.lastMessageText.isNotEmpty ? item.lastMessageText : "No messages");
                      final displayTime = isCleared ? "" : item.formattedTime;
                      final effectiveMsgIcon = isCleared ? Icons.chat_bubble_outline : msgIcon;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(peer: item.toPeerUser()),
                              ),
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                                child: Text(
                                  item.avatarInitials,
                                  style: const TextStyle(
                                    color: AppTheme.primaryIndigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: item.isOnline ? AppTheme.statusGreen : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppTheme.darkCard : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.peerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                displayTime,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      effectiveMsgIcon,
                                      size: 14,
                                      color: AppTheme.primaryIndigo,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayLastMsg,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.formatCoordinates()} • ${item.deviceModel}",
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          trailing: item.unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryIndigo,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${item.unreadCount}",
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

