class CurrentUser {
  CurrentUser({
    required this.userId,
    required this.companyId,
    required this.role,
    this.userType = 'builder_admin',
  });

  final String userId;
  final String companyId;
  final String role;
  final String userType; // "super_admin" or "builder_admin"

  bool get isSuperAdmin => userType == 'super_admin';
  bool get isBuilderAdmin => userType == 'builder_admin';

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      role: json['role'] as String,
      userType: json['user_type'] as String? ?? 'builder_admin',
    );
  }
}
