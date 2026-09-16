class EmployeeModel {
  final int id;
  final int userId;

  /// Matricule / code de l'employé
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

  /// PIN personnel de l'employé.
  ///
  /// Peut être null si l'API ne retourne pas le PIN.
  final String? pin;

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
    this.pin,
    this.department,
    this.manager,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: _toInt(json['id']),

      userId: _toInt(
        json['user_id'] ?? json['userId'],
      ),

      employeeCode:
          json['employee_code']?.toString() ??
          json['employeeCode']?.toString() ??
          '',

      firstName:
          json['first_name']?.toString() ??
          json['firstName']?.toString() ??
          '',

      lastName:
          json['last_name']?.toString() ??
          json['lastName']?.toString() ??
          '',

      fullName:
          json['full_name']?.toString() ??
          json['fullName']?.toString() ??
          '${json['first_name'] ?? json['firstName'] ?? ''} '
                  '${json['last_name'] ?? json['lastName'] ?? ''}'
              .trim(),

      phone: json['phone']?.toString(),

      profileImage:
          json['profile_image']?.toString() ??
          json['profileImage']?.toString(),

      position: json['position']?.toString(),

      hireDate:
          json['hire_date']?.toString() ??
          json['hireDate']?.toString(),

      active: _toBool(json['active']),

      email: json['email']?.toString() ?? '',

      // PIN de l'employé
      pin: _extractPin(json),

      department: json['department'] is Map
          ? Department.fromJson(
              Map<String, dynamic>.from(
                json['department'] as Map,
              ),
            )
          : null,

      manager: json['manager'] is Map
          ? Manager.fromJson(
              Map<String, dynamic>.from(
                json['manager'] as Map,
              ),
            )
          : null,
    );
  }

  // ===========================================================================
  // PIN
  // ===========================================================================

  /// Accepte plusieurs noms possibles provenant de l'API.
  ///
  /// Exemple :
  /// {
  ///   "pin": "482913"
  /// }
  ///
  /// ou :
  ///
  /// {
  ///   "employee_pin": "482913"
  /// }
  static String? _extractPin(
    Map<String, dynamic> json,
  ) {
    final value =
        json['pin'] ??
        json['employee_pin'] ??
        json['employeePin'] ??
        json['pin_code'] ??
        json['pinCode'];

    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  /// Indique si un PIN est disponible.
  bool get hasPin {
    return pin != null && pin!.trim().isNotEmpty;
  }

  // ===========================================================================
  // INITIALES
  // ===========================================================================

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

    final name = fullName.trim();

    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));

      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'
            .toUpperCase();
      }

      return parts.first[0].toUpperCase();
    }

    return '?';
  }

  // ===========================================================================
  // DEPARTEMENT
  // ===========================================================================

  String get departmentName {
    return department?.name ?? 'Aucun département';
  }

  // ===========================================================================
  // MANAGER
  // ===========================================================================

  String get managerName {
    return manager?.name ?? 'Aucun manager';
  }

  // ===========================================================================
  // POSTE
  // ===========================================================================

  String get positionName {
    final value = position?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Employé';
  }

  // ===========================================================================
  // NOM COMPLET
  // ===========================================================================

  String get displayName {
    final value = fullName.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return '$firstName $lastName'.trim();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final stringValue =
        value?.toString().toLowerCase().trim();

    return stringValue == '1' ||
        stringValue == 'true' ||
        stringValue == 'yes';
  }

  // ===========================================================================
  // JSON
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone': phone,
      'profile_image': profileImage,
      'position': position,
      'hire_date': hireDate,
      'active': active,
      'email': email,
      'pin': pin,

      if (department != null)
        'department': department!.toJson(),

      if (manager != null)
        'manager': manager!.toJson(),
    };
  }
}


// ============================================================================
// DEPARTMENT
// ============================================================================

class Department {
  final int id;
  final String name;

  const Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(
    Map<String, dynamic> json,
  ) {
    return Department(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}


// ============================================================================
// MANAGER
// ============================================================================

class Manager {
  final int id;
  final String name;

  const Manager({
    required this.id,
    required this.name,
  });

  factory Manager.fromJson(
    Map<String, dynamic> json,
  ) {
    return Manager(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}