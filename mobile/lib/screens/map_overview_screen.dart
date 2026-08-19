import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/conversation_summary.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';
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
  bool _isUserSelected = true;
  int _radiusFilterIndex = 2; // 0: 1km, 1: 5km, 2: 20km, 3: Global
  MapType _currentMapType = MapType.normal;

  LocationPoint _myLocation = LocationPoint(
    latitude: 28.6139,
    longitude: 77.2090,
    address: "Acquiring live GPS location...",
    timestamp: DateTime.now(),
  );

  double _gpsAccuracy = 0.0;
  double _gpsAltitude = 0.0;
  double _gpsSpeed = 0.0;
  int _batteryLevel = 95;

  List<PeerUser> _peers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = Dio();
      dio.options.headers['User-Agent'] = 'location-service-app/1.0';
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
      );
      if (res.statusCode == 200 && res.data != null && res.data['display_name'] != null) {
        return res.data['display_name'].toString();
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "${lat.toStringAsFixed(5)}°, ${lng.toStringAsFixed(5)}°";
  }

  Future<void> _initMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      try {
        final battery = Battery();
        _batteryLevel = await battery.batteryLevel;
      } catch (e) {
        debugPrint("Battery check info: $e");
      }

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
          _gpsAccuracy = position.accuracy;
          _gpsAltitude = position.altitude;
          _gpsSpeed = position.speed;

          final realAddress = await _reverseGeocode(position.latitude, position.longitude);

          _myLocation = LocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            address: realAddress,
            altitude: position.altitude,
            speed: position.speed,
            timestamp: DateTime.now(),
          );

          await _apiService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: realAddress,
          );
          await _apiService.updateDeviceStatus(batteryLevel: _batteryLevel);
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
            .where((s) => !DeletionStorageService().isPeerCleared(s.peerId))
            .toList();

        _peers = summaries.map((s) => s.toPeerUser()).toList();
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
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    final userName = currentUser?.name ?? "My Device";
    final userEmail = currentUser?.email ?? "Live User";
    final initials = userName.isNotEmpty
        ? userName.split(" ").map((e) => e.isNotEmpty ? e[0] : "").take(2).join().toUpperCase()
        : "YOU";

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
            tooltip: "Refresh Live GPS & Peers",
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
                      isUserSelected: _isUserSelected,
                      onSelectUser: () {
                        setState(() {
                          _isUserSelected = true;
                          _selectedPeer = null;
                        });
                      },
                      onSelectPeer: (peer) {
                        setState(() {
                          _isUserSelected = false;
                          _selectedPeer = peer;
                        });
                      },
                      isOverviewMode: true,
                      radiusZoom: _radiusFilterIndex == 0 ? 15.5 : (_radiusFilterIndex == 1 ? 13.5 : (_radiusFilterIndex == 2 ? 11.5 : 5.0)),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRadiusChip(0, "1 km"),
                            const SizedBox(width: 6),
                            _buildRadiusChip(1, "5 km"),
                            const SizedBox(width: 6),
                            _buildRadiusChip(2, "20 km"),
                            const SizedBox(width: 6),
                            _buildRadiusChip(3, "Global Radius"),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: SizedBox(
                        height: 72,
                        child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 1 + _peers.length,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // User Node ("You")
                                  final isSelected = _isUserSelected;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isUserSelected = true;
                                        _selectedPeer = null;
                                      });
                                    },
                                    child: Container(
                                      width: 190,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Card(
                                        color: isSelected
                                            ? AppTheme.primaryIndigo
                                            : (isDark ? AppTheme.darkCard : Colors.white),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: isSelected ? Colors.white24 : AppTheme.primaryIndigo.withOpacity(0.15),
                                                child: Icon(
                                                  Icons.my_location,
                                                  size: 16,
                                                  color: isSelected ? Colors.white : AppTheme.primaryIndigo,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isSelected ? Colors.white : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final peer = _peers[index - 1];
                                final isSelected = !_isUserSelected && _selectedPeer?.id == peer.id;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isUserSelected = false;
                                      _selectedPeer = peer;
                                    });
                                  },
                                  child: Container(
                                    width: 190,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Card(
                                      color: isSelected
                                          ? AppTheme.primaryViolet.withOpacity(0.95)
                                          : (isDark ? AppTheme.darkCard : Colors.white),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isSelected ? Colors.white24 : AppTheme.primaryIndigo.withOpacity(0.12),
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
                                              child: Text(
                                                peer.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isSelected ? Colors.white : null,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
                        ),
                      ],
                    )),
    );
  }

  Widget _buildUserLocationDetailsCard(bool isDark, String userName, String userEmail, String initials) {
    return Card(
      elevation: 6,
      color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryIndigo,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerLocationDetailsCard(bool isDark, PeerUser peer) {
    return Card(
      elevation: 6,
      color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryViolet,
                  child: Text(
                    peer.avatarInitials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
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
                            peer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: peer.isOnline ? AppTheme.statusGreen.withOpacity(0.18) : Colors.grey.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              peer.isOnline ? "ONLINE" : "OFFLINE",
                              style: TextStyle(
                                color: peer.isOnline ? AppTheme.statusGreen : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        peer.email,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LAT/LNG: ${peer.location.formatCoordinates()}",
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo),
                ),
                Text(
                  "Battery: ${peer.batteryLevel}%",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "📍 Address: ${peer.location.address}",
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryIndigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatDetailScreen(peer: peer)),
                      );
                    },
                    icon: const Icon(Icons.send, size: 16, color: Colors.white),
                    label: const Text("Message", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
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
