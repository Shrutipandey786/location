import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';
import '../widgets/camera_hud_overlay.dart';

class LiveCameraScreen extends StatefulWidget {
  final ValueChanged<String>? onPhotoCaptured;

  const LiveCameraScreen({
    super.key,
    this.onPhotoCaptured,
  });

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  bool _flashOn = false;
  int _batteryLevel = 90;
  LocationPoint _liveLocation = LocationPoint(
    latitude: 28.6139,
    longitude: 77.2090,
    address: "Live Camera GPS Checkpoint",
    timestamp: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _fetchLiveCameraData();
  }

  Future<void> _fetchLiveCameraData() async {
    try {
      final battery = Battery();
      _batteryLevel = await battery.batteryLevel;
    } catch (_) {}

    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          if (mounted) {
            setState(() {
              _liveLocation = LocationPoint(
                latitude: pos.latitude,
                longitude: pos.longitude,
                address: "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}",
                timestamp: DateTime.now(),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Camera GPS fetch error: $e");
    }
  }

  void _snapPhoto() {
    const imageUrl = "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=600&q=80";

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📸 Live HUD Camera Snapshot Captured & Location Tagged!"),
        duration: Duration(seconds: 2),
      ),
    );

    if (widget.onPhotoCaptured != null) {
      widget.onPhotoCaptured!(imageUrl);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Live Telemetry Camera",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.cyanAccent),
            onPressed: () {
              setState(() => _flashOn = !_flashOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: CameraHudOverlay(
        location: _liveLocation,
        deviceModel: "Android",
        batteryLevel: _batteryLevel,
        onSnapPhoto: _snapPhoto,
      ),
    );
  }
}
