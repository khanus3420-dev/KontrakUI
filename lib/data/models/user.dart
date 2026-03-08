class User {
  User({
    required this.id,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.organizationId,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final bool isActive;
  final String organizationId;
  final String role;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      organizationId: json['organization_id'] as String,
      role: json['role'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

class UserCreate {
  UserCreate({
    required this.email,
    required this.password,
    this.fullName,
    required this.organizationId,
    this.role = 'manager',
  });

  final String email;
  final String password;
  final String? fullName;
  final String organizationId;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (fullName != null && fullName!.isNotEmpty) 'full_name': fullName,
      'organization_id': organizationId,
      'role': role,
    };
  }
}
