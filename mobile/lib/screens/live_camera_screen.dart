import 'package:flutter/material.dart';
import '../data/mock_data.dart';
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

  void _snapPhoto() {
    const mockImageUrl = "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=600&q=80";

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📸 Live HUD Camera Snapshot Captured & Location Tagged!"),
        duration: Duration(seconds: 2),
      ),
    );

    if (widget.onPhotoCaptured != null) {
      widget.onPhotoCaptured!(mockImageUrl);
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
        location: MockData.myLocation,
        deviceModel: MockData.currentUser.deviceModel,
        batteryLevel: MockData.currentUser.batteryLevel,
        onSnapPhoto: _snapPhoto,
      ),
    );
  }
}
