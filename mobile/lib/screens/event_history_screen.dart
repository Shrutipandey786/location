import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final AuthApiService _apiService = AuthApiService();
  int _selectedFilterIndex = 0; // 0: All, 1: Location, 2: PTT, 3: SOS, 4: Snapshot

  List<TrackerEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  String? _getFilterType() {
    switch (_selectedFilterIndex) {
      case 1:
        return 'GPS_SYNC';
      case 2:
        return 'PTT_VOICE';
      case 3:
        return 'SOS';
      case 4:
        return 'CAMERA_TELEMETRY';
      default:
        return null;
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filterType = _getFilterType();
      final response = await _apiService.getActivities(type: filterType);
      if (response.data != null && response.data is List) {
        final listData = response.data as List<dynamic>;
        _events = listData
            .map((item) => TrackerEvent.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _events = [];
      }
      setState(() {
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : (e.message ?? "Failed to load activity history.");
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event & Activity History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Log History",
            onPressed: _loadActivities,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: "Export Event Log",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Exported Event Log (CSV Format)")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("All Logs"),
                  selected: _selectedFilterIndex == 0,
                  onSelected: (_) {
                    if (_selectedFilterIndex != 0) {
                      setState(() => _selectedFilterIndex = 0);
                      _loadActivities();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("GPS Updates"),
                  selected: _selectedFilterIndex == 1,
                  onSelected: (_) {
                    if (_selectedFilterIndex != 1) {
                      setState(() => _selectedFilterIndex = 1);
                      _loadActivities();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("PTT Calls"),
                  selected: _selectedFilterIndex == 2,
                  onSelected: (_) {
                    if (_selectedFilterIndex != 2) {
                      setState(() => _selectedFilterIndex = 2);
                      _loadActivities();
                    }
                  },
                ),

                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Snapshots"),
                  selected: _selectedFilterIndex == 4,
                  onSelected: (_) {
                    if (_selectedFilterIndex != 4) {
                      setState(() => _selectedFilterIndex = 4);
                      _loadActivities();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
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
                                onPressed: _loadActivities,
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: const Text("Retry", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_events.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadActivities,
                            color: AppTheme.primaryIndigo,
                            child: ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textSecondary),
                                        SizedBox(height: 12),
                                        Text(
                                          "No activity logs found for this filter.",
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadActivities,
                            color: AppTheme.primaryIndigo,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];

                                IconData eventIcon;
                                Color iconColor;
                                if (event.type == EventType.locationUpdate) {
                                  eventIcon = Icons.my_location;
                                  iconColor = AppTheme.primaryIndigo;
                                } else if (event.type == EventType.pttCall) {
                                  eventIcon = Icons.mic;
                                  iconColor = AppTheme.primaryViolet;
                                } else if (event.type == EventType.cameraSnapshot) {
                                  eventIcon = Icons.camera_alt;
                                  iconColor = AppTheme.accentCyan;
                                } else if (event.type == EventType.geofenceAlert) {
                                  eventIcon = Icons.shield_outlined;
                                  iconColor = AppTheme.statusAmber;
                                } else {
                                  eventIcon = Icons.warning_amber_rounded;
                                  iconColor = AppTheme.statusRed;
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(eventIcon, color: iconColor, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        event.title,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        event.formattedTime,
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Peer: ${event.peerName}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          event.details,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppTheme.darkInput : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                event.location.formatCoordinates(),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                  color: AppTheme.primaryIndigo,
                                                ),
                                              ),
                                              Text(
                                                "${event.deviceModel} (${event.batteryLevel}%)",
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ))),
          ),
        ],
      ),
    );
  }
}

