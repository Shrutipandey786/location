import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_canvas.dart';
import 'chat_detail_screen.dart';

class MapOverviewScreen extends StatefulWidget {
  const MapOverviewScreen({super.key});

  @override
  State<MapOverviewScreen> createState() => _MapOverviewScreenState();
}

class _MapOverviewScreenState extends State<MapOverviewScreen> {
  final AuthApiService _apiService = AuthApiService();
  PeerUser? _selectedPeer;
  int _radiusFilterIndex = 2; // 0: 1km, 1: 5km, 2: 20km, 3: Global
  MapType _currentMapType = MapType.normal;

  LocationPoint _myLocation = LocationPoint(
    latitude: 28.6139,
    longitude: 77.2090,
    address: "My Current Position",
    timestamp: DateTime.now(),
  );

  List<PeerUser> _peers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  Future<void> _initMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          _myLocation = LocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            address: "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
            timestamp: DateTime.now(),
          );
          _apiService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: _myLocation.address,
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching GPS location: $e");
    }

    try {
      final response = await _apiService.getConversations();
      if (response.data != null && response.data is List) {
        final listData = response.data as List<dynamic>;
        final summaries = listData
            .map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>))
            .toList();

        _peers = summaries.map((s) => s.toPeerUser()).toList();
        if (_peers.isNotEmpty && _selectedPeer == null) {
          _selectedPeer = _peers.first;
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
            : (e.message ?? "Network error fetching peer locations.");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.hybrid;
      } else if (_currentMapType == MapType.hybrid) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });

    String typeName = _currentMapType.name.toUpperCase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Map Layer Changed: $typeName"), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar_rounded, color: AppTheme.primaryIndigo),
            SizedBox(width: 8),
            Text("Network Map Overview"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Peer Locations",
            onPressed: _initMapData,
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: "Toggle Map Layer",
            onPressed: _toggleMapType,
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
                          onPressed: _initMapData,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text("Retry", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    InteractiveMapCanvas(
                      selectedPeer: _selectedPeer,
                      peers: _peers,
                      myLocation: _myLocation,
                      mapType: _currentMapType,
                      onSelectPeer: (peer) {
                        setState(() => _selectedPeer = peer);
                      },
                      isOverviewMode: true, radiusZoom: _radiusFilterIndex == 0 ? 15.5 : (_radiusFilterIndex == 1 ? 13.5 : (_radiusFilterIndex == 2 ? 11.5 : 5.0)),
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRadiusChip(0, "1 km"),
                            const SizedBox(width: 8),
                            _buildRadiusChip(1, "5 km"),
                            const SizedBox(width: 8),
                            _buildRadiusChip(2, "20 km"),
                            const SizedBox(width: 8),
                            _buildRadiusChip(3, "Global Radius"),
                          ],
                        ),
                      ),
                    ),
                    if (_peers.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkSurface : Colors.white).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: AppTheme.primaryIndigo),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${_peers.length} Connections",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _peers.length,
                                itemBuilder: (context, index) {
                                  final peer = _peers[index];
                                  final isSelected = _selectedPeer?.id == peer.id;

                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedPeer = peer),
                                    child: Container(
                                      width: 220,
                                      margin: const EdgeInsets.only(right: 10),
                                      child: Card(
                                        color: isSelected
                                            ? AppTheme.primaryViolet.withOpacity(0.9)
                                            : (isDark ? AppTheme.darkCard : Colors.white),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Colors.white24,
                                                    child: Text(
                                                      peer.avatarInitials,
                                                      style: TextStyle(
                                                        color: isSelected ? Colors.white : AppTheme.primaryIndigo,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          peer.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: isSelected ? Colors.white : null,
                                                          ),
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          peer.location.formatCoordinates(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontFamily: 'monospace',
                                                            color: isSelected ? Colors.white70 : AppTheme.primaryIndigo,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "${peer.isOnline ? "Online" : "Offline"} • ${peer.deviceModel.split(' ').first} (${peer.batteryLevel}%)",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isSelected ? Colors.white70 : Colors.grey,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => ChatDetailScreen(peer: peer),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white24,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.send,
                                                        size: 12,
                                                        color: isSelected ? Colors.white : AppTheme.primaryIndigo,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )),
    );
  }

  Widget _buildRadiusChip(int index, String label) {
    final isSelected = _radiusFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _radiusFilterIndex = index),
      selectedColor: AppTheme.primaryIndigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.primaryIndigo,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}
