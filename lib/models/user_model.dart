class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final int? employeeId;
  final int? departmentId;
  final String? createdAt;
  final String? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.employeeId,
    this.departmentId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _extractRole(json),
      employeeId: _parseInt(
        json['employee_id'] ?? json['employeeId'],
      ),
      departmentId: _parseInt(
        json['department_id'] ?? json['departmentId'],
      ),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (role != null) 'role': role,
      if (employeeId != null) 'employee_id': employeeId,
      if (departmentId != null) 'department_id': departmentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    int? employeeId,
    int? departmentId,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSuperAdmin => role == 'super_admin';

  bool get isAdminRh => role == 'admin_rh';

  bool get isManager => role == 'manager';

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name;
    }

    return email;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static String? _extractRole(Map<String, dynamic> json) {
    final role = json['role'];

    if (role is String) {
      return role;
    }

    if (role is Map<String, dynamic>) {
      return role['name']?.toString();
    }

    final roles = json['roles'];

    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;

      if (first is String) {
        return first;
      }

      if (first is Map<String, dynamic>) {
        return first['name']?.toString();
      }
    }

    return null;
  }
}