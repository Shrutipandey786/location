class User {
  final int? userId;
  final String name;
  final String email;
  final String role;

  const User({
    this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  int? get id => userId;

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? json['id'];
    int? parsedUserId;
    if (rawId is int) {
      parsedUserId = rawId;
    } else if (rawId is num) {
      parsedUserId = rawId.toInt();
    } else if (rawId is String) {
      parsedUserId = int.tryParse(rawId);
    }

    return User(
      userId: parsedUserId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'User(userId: $userId, name: $name, email: $email, role: $role)';
  }
}
