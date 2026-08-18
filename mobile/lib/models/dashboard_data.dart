import '../models/models.dart';

class DashboardActivity {
  final String id;
  final String title;
  final String details;
  final String type;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  DashboardActivity({
    required this.id,
    required this.title,
    required this.details,
    required this.type,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      type: json['type']?.toString() ?? 'LOCATION_UPDATE',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  String get formattedTime {
    if (createdAt == null) return '';
    final dt = createdAt!.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class DashboardData {
  final String userName;
  final String userEmail;
  final String userRole;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool online;
  final bool isBroadcasting;
  final int batteryLevel;
  final String statusMessage;
  final List<DashboardActivity> recentActivities;

  DashboardData({
    required this.userName,
    required this.userEmail,
    required this.userRole,
    this.latitude,
    this.longitude,
    this.address,
    this.online = true,
    this.isBroadcasting = true,
    this.batteryLevel = 100,
    required this.statusMessage,
    required this.recentActivities,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final locationJson = json['location'] as Map<String, dynamic>?;
    final deviceJson = json['deviceStatus'] as Map<String, dynamic>?;
    final activitiesJson = json['recentActivities'] as List<dynamic>? ?? [];

    return DashboardData(
      userName: userJson['name']?.toString() ?? 'User',
      userEmail: userJson['email']?.toString() ?? '',
      userRole: userJson['role']?.toString() ?? 'USER',
      latitude: locationJson != null && locationJson['latitude'] != null 
          ? (locationJson['latitude'] as num).toDouble() : null,
      longitude: locationJson != null && locationJson['longitude'] != null 
          ? (locationJson['longitude'] as num).toDouble() : null,
      address: locationJson?['address']?.toString(),
      online: deviceJson?['online'] == true,
      isBroadcasting: deviceJson?['isBroadcasting'] == true,
      batteryLevel: deviceJson?['batteryLevel'] != null 
          ? (deviceJson!['batteryLevel'] as num).toInt() : 100,
      statusMessage: deviceJson?['statusMessage']?.toString() ?? 'Active',
      recentActivities: activitiesJson
          .map((item) => DashboardActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory DashboardData.fallback() {
    return DashboardData(
      userName: 'User',
      userEmail: '',
      userRole: 'USER',
      latitude: 28.6139,
      longitude: 77.2090,
      address: 'Delhi, India',
      online: true,
      isBroadcasting: true,
      batteryLevel: 95,
      statusMessage: 'Active',
      recentActivities: [],
    );
  }

  bool get isOnline => online;
  String get deviceName => "Android";

  LocationPoint get currentLocation => LocationPoint(
    latitude: latitude ?? 28.6139,
    longitude: longitude ?? 77.2090,
    address: address ?? (latitude != null && longitude != null ? "${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}" : "Delhi, India"),
    timestamp: DateTime.now(),
  );

  String formatCoordinates() {
    if (latitude == null || longitude == null) return "28.6139, 77.2090";
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }
}
