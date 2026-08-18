import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
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
  String _searchQuery = "";
  int _selectedFilterIndex = 0; // 0: All, 1: Online, 2: Nearby

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPeers = MockData.peers.where((peer) {
      final matchesSearch = peer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          peer.email.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilterIndex == 1) return peer.isOnline;
      if (_selectedFilterIndex == 2) return peer.distanceKm < 2.0;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("People & Contacts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Add Peer QR scanner opened")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: "Search peer by name or email...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("All Peers"),
                  selected: _selectedFilterIndex == 0,
                  onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Online Now"),
                  selected: _selectedFilterIndex == 1,
                  onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Nearby (< 2 km)"),
                  selected: _selectedFilterIndex == 2,
                  onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Peer List View
          Expanded(
            child: filteredPeers.isEmpty
                ? const Center(
                    child: Text(
                      "No matching peers found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredPeers.length,
                    itemBuilder: (context, index) {
                      final peer = filteredPeers[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                                        child: Text(
                                          peer.avatarInitials,
                                          style: const TextStyle(
                                            color: AppTheme.primaryIndigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                                fontSize: 16,
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
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 13,
                                              color: AppTheme.primaryIndigo,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "📍 ${peer.distanceKm} km away • ${peer.location.address}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryIndigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

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
          ),
        ],
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
