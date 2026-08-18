import 'models.dart';

class ConversationSummary {
  final int conversationId;
  final String peerId;
  final String peerName;
  final String peerEmail;
  final String avatarInitials;
  final bool isOnline;
  final String statusMessage;
  final int batteryLevel;
  final String deviceModel;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int unreadCount;
  final String lastMessageText;
  final String lastMessageType;
  final DateTime? lastMessageTime;

  ConversationSummary({
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    required this.peerEmail,
    required this.avatarInitials,
    required this.isOnline,
    required this.statusMessage,
    required this.batteryLevel,
    required this.deviceModel,
    this.latitude,
    this.longitude,
    this.address,
    required this.unreadCount,
    required this.lastMessageText,
    required this.lastMessageType,
    this.lastMessageTime,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: json['conversationId'] != null ? (json['conversationId'] as num).toInt() : 0,
      peerId: json['peerId']?.toString() ?? '',
      peerName: json['peerName']?.toString() ?? 'User',
      peerEmail: json['peerEmail']?.toString() ?? '',
      avatarInitials: json['avatarInitials']?.toString() ?? 'U',
      isOnline: json['isOnline'] == true,
      statusMessage: json['statusMessage']?.toString() ?? 'Active',
      batteryLevel: json['batteryLevel'] != null ? (json['batteryLevel'] as num).toInt() : 100,
      deviceModel: json['deviceModel']?.toString() ?? 'Android',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address']?.toString(),
      unreadCount: json['unreadCount'] != null ? (json['unreadCount'] as num).toInt() : 0,
      lastMessageText: json['lastMessageText']?.toString() ?? '',
      lastMessageType: json['lastMessageType']?.toString() ?? 'TEXT',
      lastMessageTime: json['lastMessageTime'] != null ? DateTime.tryParse(json['lastMessageTime'].toString()) : null,
    );
  }

  PeerUser toPeerUser() {
    return PeerUser(
      id: peerId,
      name: peerName,
      email: peerEmail,
      avatarInitials: avatarInitials,
      isOnline: isOnline,
      statusMessage: statusMessage,
      batteryLevel: batteryLevel,
      deviceModel: deviceModel,
      location: LocationPoint(
        latitude: latitude ?? 28.6139,
        longitude: longitude ?? 77.2090,
        address: address ?? "Current Checkpoint",
        timestamp: lastMessageTime ?? DateTime.now(),
      ),
      distanceKm: 1.2,
      lastSeen: lastMessageTime ?? DateTime.now(),
    );
  }

  String get formattedTime {
    if (lastMessageTime == null) return '';
    final dt = lastMessageTime!.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String formatCoordinates() {
    if (latitude == null || longitude == null) return "No GPS Data";
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }
}
