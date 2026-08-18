import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CameraHudOverlay extends StatelessWidget {
  final LocationPoint location;
  final String deviceModel;
  final int batteryLevel;
  final VoidCallback? onSnapPhoto;

  const CameraHudOverlay({
    super.key,
    required this.location,
    required this.deviceModel,
    required this.batteryLevel,
    this.onSnapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Viewfinder Background Graphic
          Positioned.fill(
            child: Container(
              color: Colors.grey.shade900,
              child: Image.network(
                "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=1000&q=80",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.videocam_outlined, size: 64, color: Colors.white30),
                  );
                },
              ),
            ),
          ),

          // HUD Lines
          Positioned.fill(
            child: CustomPaint(
              painter: CameraHudPainter(),
            ),
          ),

          // Top Location Banner Card
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.statusRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "CAMERA HUD",
                        style: TextStyle(
                          color: AppTheme.primaryIndigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "📍 ${location.formatCoordinates()}",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control & Shutter Button Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        deviceModel,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "⚡ $batteryLevel%",
                        style: const TextStyle(color: AppTheme.statusGreen, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "⛰️ ${location.altitude}m",
                        style: const TextStyle(color: AppTheme.primaryIndigo, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Shutter Button
                GestureDetector(
                  onTap: onSnapPhoto,
                  child: Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryIndigo,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CameraHudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Target Crosshair
    canvas.drawCircle(center, 24, paint);
    canvas.drawLine(Offset(center.dx - 36, center.dy), Offset(center.dx - 12, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 12, center.dy), Offset(center.dx + 36, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 36), Offset(center.dx, center.dy - 12), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 12), Offset(center.dx, center.dy + 36), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
