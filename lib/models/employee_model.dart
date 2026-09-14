class EmployeeModel {
  final int id;
  final int userId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final String? profileImage;
  final String? position;
  final String? hireDate;
  final bool active;
  final String email;
  final Department? department;
  final Manager? manager;

  const EmployeeModel({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phone,
    this.profileImage,
    this.position,
    this.hireDate,
    required this.active,
    required this.email,
    this.department,
    this.manager,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      employeeCode: json['employee_code']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      phone: json['phone']?.toString(),
      profileImage: json['profile_image']?.toString(),
      position: json['position']?.toString(),
      hireDate: json['hire_date']?.toString(),
      active: _toBool(json['active']),
      email: json['email']?.toString() ?? '',

      department: json['department'] is Map<String, dynamic>
          ? Department.fromJson(
              json['department'] as Map<String, dynamic>,
            )
          : null,

      manager: json['manager'] is Map<String, dynamic>
          ? Manager.fromJson(
              json['manager'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Initiales de l'employé
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }

    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }

    if (last.isNotEmpty) {
      return last[0].toUpperCase();
    }

    if (fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));

      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }

      return parts.first[0].toUpperCase();
    }

    return '?';
  }

  /// Nom du département directement utilisable dans l'UI
  String get departmentName {
    return department?.name ?? 'Aucun département';
  }

  /// Nom du manager directement utilisable dans l'UI
  String get managerName {
    return manager?.name ?? 'Aucun manager';
  }

  /// Position avec valeur par défaut
  String get positionName {
    return position?.trim().isNotEmpty == true
        ? position!.trim()
        : 'Employé';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    final stringValue = value?.toString().toLowerCase();

    return stringValue == '1' ||
        stringValue == 'true' ||
        stringValue == 'yes';
  }
}


class Department {
  final int id;
  final String name;

  const Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}


class Manager {
  final int id;
  final String name;

  const Manager({
    required this.id,
    required this.name,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}