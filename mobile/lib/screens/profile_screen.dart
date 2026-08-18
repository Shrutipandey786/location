import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthApiService _apiService = AuthApiService();
  final Battery _battery = Battery();

  bool _isLoading = true;
  String? _errorMessage;

  String _name = '';
  String _email = '';
  String _role = 'USER';

  String _deviceModel = 'Android';
  int _batteryLevel = 100;
  double _latitude = 28.6139;
  double _longitude = 77.2090;
  double _altitude = 120.5;
  double _speed = 0.0;
  int _networkLatency = 18;

  bool _locationSharing = true;
  bool _highPrecisionGps = true;
  bool _darkThemeMode = false;
  bool _autoPlayPtt = true;
  bool _stealthMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRes = await _apiService.getProfile();
      final telemetryRes = await _apiService.getDeviceTelemetry();
      final settingsRes = await _apiService.getSettings();

      if (profileRes.data != null) {
        _name = profileRes.data['name']?.toString() ?? '';
        _email = profileRes.data['email']?.toString() ?? '';
        _role = profileRes.data['role']?.toString() ?? 'USER';
      }

      if (telemetryRes.data != null) {
        _deviceModel = telemetryRes.data['deviceModel']?.toString() ?? 'Android';
        _batteryLevel = telemetryRes.data['batteryLevel'] != null ? (telemetryRes.data['batteryLevel'] as num).toInt() : 100;
        _latitude = telemetryRes.data['latitude'] != null ? (telemetryRes.data['latitude'] as num).toDouble() : 28.6139;
        _longitude = telemetryRes.data['longitude'] != null ? (telemetryRes.data['longitude'] as num).toDouble() : 77.2090;
        _altitude = telemetryRes.data['altitude'] != null ? (telemetryRes.data['altitude'] as num).toDouble() : 120.5;
        _speed = telemetryRes.data['speed'] != null ? (telemetryRes.data['speed'] as num).toDouble() : 0.0;
        _networkLatency = telemetryRes.data['networkLatencyMs'] != null ? (telemetryRes.data['networkLatencyMs'] as num).toInt() : 18;
      }

      if (settingsRes.data != null) {
        _locationSharing = settingsRes.data['locationSharing'] == true;
        _highPrecisionGps = settingsRes.data['highPrecisionGps'] == true;
        _darkThemeMode = settingsRes.data['darkThemeMode'] == true;
        _autoPlayPtt = settingsRes.data['autoPlayPtt'] == true;
        _stealthMode = settingsRes.data['stealthMode'] == true;
      }

      try {
        final batLevel = await _battery.batteryLevel;
        _batteryLevel = batLevel;
      } catch (_) {}

      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _altitude = pos.altitude;
          _speed = pos.speed;
        }
      } catch (_) {}

      setState(() {
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : (e.message ?? "Failed to connect to backend profile service.");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final Map<String, dynamic> updateData = {
      'locationSharing': _locationSharing,
      'highPrecisionGps': _highPrecisionGps,
      'darkThemeMode': _darkThemeMode,
      'autoPlayPtt': _autoPlayPtt,
      'stealthMode': _stealthMode,
    };
    updateData[key] = value;

    try {
      final res = await _apiService.updateSettings(updateData);
      if (res.data != null) {
        setState(() {
          _locationSharing = res.data['locationSharing'] == true;
          _highPrecisionGps = res.data['highPrecisionGps'] == true;
          _darkThemeMode = res.data['darkThemeMode'] == true;
          _autoPlayPtt = res.data['autoPlayPtt'] == true;
          _stealthMode = res.data['stealthMode'] == true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update setting in PostgreSQL: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final String displayName = _name.isNotEmpty ? _name : (user?.name ?? "Active Peer");
    final String displayEmail = _email.isNotEmpty ? _email : (user?.email ?? "");
    final String initials = displayName.isNotEmpty
        ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryIndigo),
      );
    } else if (_errorMessage != null) {
      content = Center(
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
                onPressed: _loadProfileData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryIndigo,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayEmail,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.statusGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Role: $_role",
                              style: const TextStyle(
                                color: AppTheme.statusGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sensors, color: AppTheme.primaryIndigo, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Device Telemetry Status",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTelemetryRow("Device Model", _deviceModel),
                    _buildTelemetryRow("Battery Level", "$_batteryLevel% (Optimal)"),
                    _buildTelemetryRow("Current Coords", "${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}"),
                    _buildTelemetryRow("Altitude / Speed", "${_altitude.toStringAsFixed(1)}m / ${_speed.toStringAsFixed(1)} km/h"),
                    _buildTelemetryRow("Network Latency", "$_networkLatency ms (Peer Mesh Direct)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Broadcast Live Location", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Share GPS coordinates in realtime with peers"),
                    value: _locationSharing,
                    activeColor: AppTheme.primaryIndigo,
                    onChanged: (val) {
                      setState(() => _locationSharing = val);
                      _updateSetting('locationSharing', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("High Precision GPS", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("1-meter resolution location sampling"),
                    value: _highPrecisionGps,
                    activeColor: AppTheme.primaryIndigo,
                    onChanged: (val) {
                      setState(() => _highPrecisionGps = val);
                      _updateSetting('highPrecisionGps', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Dark Theme Mode", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Toggle deep indigo dark UI interface"),
                    value: _darkThemeMode,
                    activeColor: AppTheme.primaryViolet,
                    onChanged: (val) {
                      setState(() => _darkThemeMode = val);
                      _updateSetting('darkThemeMode', val);
                      if (widget.onToggleTheme != null) widget.onToggleTheme!();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("PTT Loudspeaker Auto-Play", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Automatically play incoming peer voice calls"),
                    value: _autoPlayPtt,
                    activeColor: AppTheme.primaryIndigo,
                    onChanged: (val) {
                      setState(() => _autoPlayPtt = val);
                      _updateSetting('autoPlayPtt', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Stealth Mode", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Hide active online indicator from contacts"),
                    value: _stealthMode,
                    activeColor: AppTheme.primaryIndigo,
                    onChanged: (val) {
                      setState(() => _stealthMode = val);
                      _updateSetting('stealthMode', val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
                  foregroundColor: AppTheme.statusRed,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.statusRed.withOpacity(0.3)),
                ),
                onPressed: () async {
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text("DISCONNECT / LOGOUT"),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Telemetry"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Profile & Sensors",
            onPressed: _loadProfileData,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Peer QR Code Share opened")),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
