import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeletionStorageService {
  static final DeletionStorageService _instance = DeletionStorageService._internal();
  factory DeletionStorageService() => _instance;
  DeletionStorageService._internal();

  final Set<String> _clearedPeerIds = {};
  final Set<String> _deletedMessageIds = {};
  bool _isInitialized = false;

  Set<String> get clearedPeerIds => Set.unmodifiable(_clearedPeerIds);
  Set<String> get deletedMessageIds => Set.unmodifiable(_deletedMessageIds);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleared = prefs.getStringList('cleared_peer_ids') ?? [];
      final deleted = prefs.getStringList('deleted_message_ids') ?? [];

      _clearedPeerIds.addAll(cleared);
      _deletedMessageIds.addAll(deleted);
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error initializing DeletionStorageService: $e");
    }
  }

  Future<void> clearAllLocalDeletions() async {
    _clearedPeerIds.clear();
    _deletedMessageIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cleared_peer_ids');
      await prefs.remove('deleted_message_ids');
    } catch (e) {
      debugPrint("Error clearing local deletions: $e");
    }
  }

  Future<void> addClearedPeer(String peerId, [String? currentUserId]) async {
    if (peerId.isEmpty) return;
    final key = (currentUserId != null && currentUserId.isNotEmpty) ? "${currentUserId}_$peerId" : peerId;
    _clearedPeerIds.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cleared_peer_ids', _clearedPeerIds.toList());
    } catch (e) {
      debugPrint("Error saving cleared peer ID: $e");
    }
  }

  Future<void> addDeletedMessage(String messageId) async {
    if (messageId.isEmpty) return;
    _deletedMessageIds.add(messageId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('deleted_message_ids', _deletedMessageIds.toList());
    } catch (e) {
      debugPrint("Error saving deleted message ID: $e");
    }
  }

  bool isPeerCleared(String peerId, [String? currentUserId]) {
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return _clearedPeerIds.contains("${currentUserId}_$peerId");
    }
    return _clearedPeerIds.contains(peerId);
  }

  bool isMessageDeleted(String messageId) {
    return _deletedMessageIds.contains(messageId);
  }
}
