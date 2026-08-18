enum MessageStatus { sent, delivered, read }

enum MessageType { text, location, camera, pttVoice, statusPreset, sosAlert }

enum EventType { locationUpdate, geofenceAlert, sosAlert, pttCall, cameraSnapshot }

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final double altitude;
  final double speed;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.altitude = 120.5,
    this.speed = 0.0,
    required this.timestamp,
  });

  String formatCoordinates() {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}

class PeerUser {
  final String id;
  final String name;
  final String email;
  final String avatarInitials;
  final bool isOnline;
  final String statusMessage;
  final int batteryLevel;
  final String deviceModel;
  final LocationPoint location;
  final double distanceKm;
  final DateTime lastSeen;
  final bool isSharingLocation;

  const PeerUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarInitials,
    this.isOnline = true,
    required this.statusMessage,
    required this.batteryLevel,
    required this.deviceModel,
    required this.location,
    required this.distanceKm,
    required this.lastSeen,
    this.isSharingLocation = true,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final LocationPoint? location;
  final String deviceModel;
  final int batteryLevel;
  final MessageType type;
  final String? cameraImageUrl;
  final String? audioUrl;
  final int? pttDurationSeconds;
  final List<double>? audioWaveform;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.delivered,
    this.location,
    required this.deviceModel,
    required this.batteryLevel,
    this.type = MessageType.text,
    this.cameraImageUrl,
    this.audioUrl,
    this.pttDurationSeconds,
    this.audioWaveform,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderIdStr = json['senderId']?.toString() ?? '';
    final isMe = senderIdStr == currentUserId;

    MessageType msgType = MessageType.text;
    final typeStr = json['type']?.toString() ?? 'TEXT';
    if (typeStr == 'LOCATION') {
      msgType = MessageType.location;
    } else if (typeStr == 'CAMERA') {
      msgType = MessageType.camera;
    } else if (typeStr == 'PTT_VOICE') {
      msgType = MessageType.pttVoice;
    } else if (typeStr == 'SOS_ALERT') {
      msgType = MessageType.sosAlert;
    } else if (typeStr == 'STATUS_PRESET') {
      msgType = MessageType.statusPreset;
    }

    LocationPoint? locPoint;
    if (json['latitude'] != null && json['longitude'] != null) {
      locPoint = LocationPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address']?.toString() ?? 'Location Pin',
        timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: isMe ? "user_me" : senderIdStr,
      senderName: json['senderName']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      status: json['isRead'] == true ? MessageStatus.read : MessageStatus.delivered,
      location: locPoint,
      deviceModel: 'Android',
      batteryLevel: 100,
      type: msgType,
      cameraImageUrl: json['cameraImageUrl']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      pttDurationSeconds: json['pttDurationSeconds'] != null ? (json['pttDurationSeconds'] as num).toInt() : null,
      audioWaveform: typeStr == 'PTT_VOICE' ? [0.3, 0.7, 0.9, 0.4, 0.8, 0.2] : null,
    );
  }

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class TrackerEvent {
  final String id;
  final EventType type;
  final String title;
  final String details;
  final DateTime timestamp;
  final String peerId;
  final String peerName;
  final LocationPoint location;
  final String deviceModel;
  final int batteryLevel;

  const TrackerEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.timestamp,
    required this.peerId,
    required this.peerName,
    required this.location,
    required this.deviceModel,
    required this.batteryLevel,
  });

  factory TrackerEvent.fromJson(Map<String, dynamic> json) {
    EventType evType = EventType.locationUpdate;
    final typeStr = json['type']?.toString() ?? 'GPS_SYNC';
    if (typeStr == 'PTT_VOICE' || typeStr == 'PTT_CALL') {
      evType = EventType.pttCall;
    } else if (typeStr == 'SOS' || typeStr == 'SOS_ALERT') {
      evType = EventType.sosAlert;
    } else if (typeStr == 'CAMERA_TELEMETRY' || typeStr == 'CAMERA_SNAPSHOT') {
      evType = EventType.cameraSnapshot;
    } else if (typeStr == 'GEOFENCE' || typeStr == 'GEOFENCE_ALERT') {
      evType = EventType.geofenceAlert;
    }

    final lat = json['latitude'] != null ? (json['latitude'] as num).toDouble() : 28.6139;
    final lng = json['longitude'] != null ? (json['longitude'] as num).toDouble() : 77.2090;

    return TrackerEvent(
      id: json['id']?.toString() ?? '',
      type: evType,
      title: json['title']?.toString() ?? 'Activity Log',
      details: json['details']?.toString() ?? 'Activity logged in system.',
      timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      peerId: 'user',
      peerName: json['peerName']?.toString() ?? 'System Node',
      location: LocationPoint(
        latitude: lat,
        longitude: lng,
        address: json['address']?.toString() ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      ),
      deviceModel: json['deviceModel']?.toString() ?? 'Android',
      batteryLevel: json['batteryLevel'] != null ? (json['batteryLevel'] as num).toInt() : 100,
    );
  }

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}


