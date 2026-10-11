class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isRegistered;
  final String createdAt;
  final String phone;
  final String vehicleType;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isRegistered,
    required this.createdAt,
    this.phone = '',
    this.vehicleType = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isRegistered: json['isRegistered'] as bool? ?? true,
      createdAt: json['createdAt']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'isRegistered': isRegistered,
        'createdAt': createdAt,
        'phone': phone,
        'vehicleType': vehicleType,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isRegistered,
    String? createdAt,
    String? phone,
    String? vehicleType,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isRegistered: isRegistered ?? this.isRegistered,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  /// Returns initials from the name (e.g. "Arjun Sharma" → "AS")
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Member since (formatted as "May 2026")
  String get memberSince {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
