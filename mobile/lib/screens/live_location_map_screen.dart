import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/map_canvas.dart';
import 'chat_detail_screen.dart';
import 'push_to_talk_screen.dart';

class LiveLocationMapScreen extends StatefulWidget {
  final PeerUser? peer;

  const LiveLocationMapScreen({
    super.key,
    this.peer,
  });

  @override
  State<LiveLocationMapScreen> createState() => _LiveLocationMapScreenState();
}

class _LiveLocationMapScreenState extends State<LiveLocationMapScreen> {
  late PeerUser _activePeer;
  bool _isTracking = true;
  MapType _mapType = MapType.normal;

  LocationPoint _myLocation = LocationPoint(
    latitude: 28.6139,
    longitude: 77.2090,
    address: "My Current Position",
    timestamp: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.peer != null) {
      _activePeer = widget.peer!;
    } else {
      _activePeer = PeerUser(
        id: "peer_default",
        name: "Connected Peer",
        email: "peer@example.com",
        avatarInitials: "CP",
        statusMessage: "Active",
        batteryLevel: 90,
        deviceModel: "Android",
        location: LocationPoint(
          latitude: 28.6139,
          longitude: 77.2090,
          address: "Live Location",
          timestamp: DateTime.now(),
        ),
        distanceKm: 0.0,
        lastSeen: DateTime.now(),
      );
    }
    _fetchLiveLocation();
  }

  Future<void> _fetchLiveLocation() async {
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
          if (mounted) {
            setState(() {
              _myLocation = LocationPoint(
                latitude: position.latitude,
                longitude: position.longitude,
                address: "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
                timestamp: DateTime.now(),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Live GPS fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Live Map: ${_activePeer.name}"),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.gps_fixed : Icons.gps_not_fixed, color: AppTheme.primaryIndigo),
            onPressed: () {
              setState(() => _isTracking = !_isTracking);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isTracking ? "Live GPS auto-lock enabled" : "Live GPS auto-lock paused"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveMapCanvas(
            selectedPeer: _activePeer,
            peers: [_activePeer],
            myLocation: _myLocation,
            mapType: _mapType,
            onSelectPeer: (p) => setState(() => _activePeer = p),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: (isDark ? AppTheme.darkSurface : Colors.white).withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                      child: Text(
                        _activePeer.avatarInitials,
                        style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold),
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
                                _activePeer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isTracking ? "LIVE LOCK" : "PAUSED",
                                  style: const TextStyle(
                                    color: AppTheme.statusGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activePeer.location.formatCoordinates(),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primaryIndigo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol("BATTERY", "${_activePeer.batteryLevel}%"),
                        _buildMetricCol("STATUS", _activePeer.isOnline ? "ONLINE" : "OFFLINE"),
                        _buildMetricCol("DEVICE", _activePeer.deviceModel.split(" ").first),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(peer: _activePeer),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text("Message Peer"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
                            padding: const EdgeInsets.all(14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PushToTalkScreen(selectedPeer: _activePeer),
                              ),
                            );
                          },
                          child: const Icon(Icons.mic, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
