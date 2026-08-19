import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show MapType;
import 'package:latlong2/latlong.dart' as ll;

import '../models/models.dart';
import '../theme/app_theme.dart';

class InteractiveMapCanvas extends StatefulWidget {
  final PeerUser? selectedPeer;
  final List<PeerUser> peers;
  final LocationPoint myLocation;
  final ValueChanged<PeerUser>? onSelectPeer;
  final VoidCallback? onSelectUser;
  final bool isOverviewMode;
  final MapType mapType;
  final double? radiusZoom;
  final bool isUserSelected;

  const InteractiveMapCanvas({
    super.key,
    this.selectedPeer,
    required this.peers,
    required this.myLocation,
    this.onSelectPeer,
    this.onSelectUser,
    this.isOverviewMode = false,
    this.mapType = MapType.normal,
    this.radiusZoom,
    this.isUserSelected = false,
  });

  @override
  State<InteractiveMapCanvas> createState() => _InteractiveMapCanvasState();
}

class _InteractiveMapCanvasState extends State<InteractiveMapCanvas> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.radiusZoom != oldWidget.radiusZoom && widget.radiusZoom != null) {
      final double centerLat = widget.isUserSelected ? widget.myLocation.latitude : (widget.selectedPeer?.location.latitude ?? widget.myLocation.latitude);
      final double centerLng = widget.isUserSelected ? widget.myLocation.longitude : (widget.selectedPeer?.location.longitude ?? widget.myLocation.longitude);
      _mapController.move(ll.LatLng(centerLat, centerLng), widget.radiusZoom!);
    } else if (widget.isUserSelected && !oldWidget.isUserSelected) {
      _mapController.move(
        ll.LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
        15.5,
      );
    } else if (widget.selectedPeer != oldWidget.selectedPeer && widget.selectedPeer != null) {
      _mapController.move(
        ll.LatLng(
          widget.selectedPeer!.location.latitude,
          widget.selectedPeer!.location.longitude,
        ),
        15.5,
      );
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(3.0, 19.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(3.0, 19.0));
  }

  void _recenterToUser() {
    if (widget.onSelectUser != null) {
      widget.onSelectUser!();
    }
    _mapController.move(
      ll.LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
      15.5,
    );
  }

  String _getTileUrl(bool isDark) {
    switch (widget.mapType) {
      case MapType.satellite:
      case MapType.hybrid:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapType.terrain:
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case MapType.normal:
      default:
        if (isDark) {
          return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
        }
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  List<String> _getSubdomains() {
    if (widget.mapType == MapType.satellite || widget.mapType == MapType.hybrid || widget.mapType == MapType.terrain) {
      return ['mt0', 'mt1', 'mt2', 'mt3'];
    }
    return ['a', 'b', 'c', 'd'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double centerLat = widget.isUserSelected
        ? widget.myLocation.latitude
        : (widget.selectedPeer?.location.latitude ?? widget.myLocation.latitude);
    final double centerLng = widget.isUserSelected
        ? widget.myLocation.longitude
        : (widget.selectedPeer?.location.longitude ?? widget.myLocation.longitude);

    final List<Marker> markers = [];

    // 1. Current User Marker (You) with Animated Pulse Ring & Selection Glow
    markers.add(
      Marker(
        point: ll.LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
        width: 72,
        height: 72,
        child: GestureDetector(
          onTap: () {
            if (widget.onSelectUser != null) {
              widget.onSelectUser!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("My Device (You) - Live GPS Active"), duration: Duration(seconds: 1)),
              );
            }
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.35);
              final opacity = (1.0 - _pulseController.value).clamp(0.1, 0.4);
              final isUserActive = widget.isUserSelected;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (isUserActive ? AppTheme.statusGreen : AppTheme.primaryIndigo).withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUserActive ? AppTheme.statusGreen : AppTheme.primaryIndigo,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.0),
                      boxShadow: [
                        BoxShadow(
                          color: isUserActive ? AppTheme.statusGreen.withOpacity(0.5) : Colors.black38,
                          blurRadius: isUserActive ? 12 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // 2. Connected Peer Markers from PostgreSQL
    for (final peer in widget.peers) {
      final isSelected = !widget.isUserSelected && widget.selectedPeer?.id == peer.id;

      markers.add(
        Marker(
          point: ll.LatLng(peer.location.latitude, peer.location.longitude),
          width: 84,
          height: 74,
          child: GestureDetector(
            onTap: () {
              if (widget.onSelectPeer != null) {
                widget.onSelectPeer!(peer);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryIndigo : (isDark ? Colors.black87 : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    peer.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: isSelected ? AppTheme.primaryViolet : AppTheme.primaryIndigo,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                        child: Text(
                          peer.avatarInitials,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryViolet : AppTheme.primaryIndigo,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: peer.isOnline ? AppTheme.statusGreen : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isSatelliteOrHybrid = widget.mapType == MapType.satellite || widget.mapType == MapType.hybrid;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: ll.LatLng(centerLat, centerLng),
            initialZoom: widget.radiusZoom ?? (widget.isOverviewMode ? 13.0 : 15.0),
            minZoom: 3.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _getTileUrl(isDark),
              subdomains: _getSubdomains(),
              userAgentPackageName: 'com.locationservice.tracker',
            ),
            if (isSatelliteOrHybrid)
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=h&x={x}&y={y}&z={z}',
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: 'com.locationservice.tracker',
              ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: ll.LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
                  color: AppTheme.primaryIndigo.withOpacity(0.08),
                  borderColor: AppTheme.primaryIndigo.withOpacity(0.4),
                  borderStrokeWidth: 1.5,
                  radius: 80.0,
                ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: 16,
          top: 100,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                onPressed: _zoomIn,
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                onPressed: _zoomOut,
                child: const Icon(Icons.remove, size: 20),
              ),
              const SizedBox(height: 14),
              FloatingActionButton.small(
                heroTag: 'map_recenter_gps',
                backgroundColor: widget.isUserSelected ? AppTheme.statusGreen : AppTheme.primaryIndigo,
                foregroundColor: Colors.white,
                onPressed: _recenterToUser,
                child: const Icon(Icons.gps_fixed, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
