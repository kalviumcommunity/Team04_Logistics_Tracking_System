class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final int? activeDeliveriesCount;
  final String? status; // AVAILABLE, ON_DUTY, etc.

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.activeDeliveriesCount,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return UserModel(
      id: docId ?? (json['uid'] as String? ?? json['id'] as String? ?? ''),
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
      role: (json['role'] as String? ?? 'DISPATCHER').toUpperCase(),
      avatarUrl: json['avatarUrl'] as String?,
      activeDeliveriesCount: json['activeDeliveriesCount'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'id': id,
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      'activeDeliveriesCount': activeDeliveriesCount,
      'status': status,
    };
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String get roleDisplayName {
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'OPERATIONS':
      case 'OPERATIONS_MANAGER':
        return 'Operations Manager';
      case 'DISPATCHER':
        return 'Dispatcher';
      case 'EXECUTIVE':
      case 'DELIVERY_EXECUTIVE':
      case 'FIELD_EXECUTIVE':
        return 'Delivery Executive';
      default:
        return role;
    }
  }
}
