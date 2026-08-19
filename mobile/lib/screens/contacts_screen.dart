import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'live_location_map_screen.dart';
import 'push_to_talk_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final AuthApiService _apiService = AuthApiService();
  String _searchQuery = "";
  int _selectedFilterIndex = 0; // 0: All, 1: Online, 2: Nearby

  List<PeerUser> _peers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
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
      setState(() {
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : (e.message ?? "Network error fetching registered contacts.");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPeers = _peers.where((peer) {
      final matchesSearch = peer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          peer.email.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilterIndex == 1) return peer.isOnline;
      if (_selectedFilterIndex == 2) return peer.distanceKm < 5.0;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("People & Contacts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search registered users...",
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryIndigo),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterChip(0, "All (${_peers.length})"),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, "Online"),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, "Nearby"),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo))
                : (_errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppTheme.statusRed),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
                              onPressed: _loadContacts,
                              child: const Text("Retry", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : filteredPeers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  "No registered users found matching filter.",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadContacts,
                            color: AppTheme.primaryIndigo,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredPeers.length,
                              itemBuilder: (context, index) {
                                final peer = filteredPeers[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: AppTheme.primaryIndigo,
                                                  child: Text(
                                                    peer.avatarInitials,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: peer.isOnline ? AppTheme.statusGreen : Colors.grey,
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
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        peer.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.battery_charging_full, size: 14, color: Colors.green),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            "${peer.batteryLevel}%",
                                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    peer.statusMessage,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on_outlined,
                                                        size: 13,
                                                        color: AppTheme.primaryIndigo,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          "📍 ${peer.location.address}",
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppTheme.primaryIndigo,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),

                                        // Direct Quick Action Buttons Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildActionButton(
                                              context,
                                              icon: Icons.chat_bubble_outline,
                                              label: "Chat",
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatDetailScreen(peer: peer),
                                                  ),
                                                );
                                              },
                                            ),
                                            _buildActionButton(
                                              context,
                                              icon: Icons.map_outlined,
                                              label: "Live Map",
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => LiveLocationMapScreen(peer: peer),
                                                  ),
                                                );
                                              },
                                            ),
                                            _buildActionButton(
                                              context,
                                              icon: Icons.mic_none_outlined,
                                              label: "PTT Call",
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => PushToTalkScreen(selectedPeer: peer),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
      selectedColor: AppTheme.primaryIndigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.primaryIndigo,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryIndigo),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
