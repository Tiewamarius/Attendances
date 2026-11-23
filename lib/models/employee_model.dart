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

  EmployeeModel({
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
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      employeeCode: json['employee_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      phone: json['phone'],
      profileImage: json['profile_image'],
      position: json['position'],
      hireDate: json['hire_date'],
      active: json['active'] ?? false,
      email: json['email'] ?? '',
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      manager: json['manager'] != null
          ? Manager.fromJson(json['manager'])
          : null,
    );
  }

  String? get initials => null;
}

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  /// L'API renvoie tantôt un objet {id, name}, tantôt (au login) seulement
  /// le nom du département sous forme de texte.
  factory Department.fromJson(dynamic json) {
    if (json is Map) {
      return Department(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
    }

    return Department(id: 0, name: json?.toString() ?? '');
  }
}

class Manager {
  final int id;
  final String name;

  Manager({required this.id, required this.name});

  factory Manager.fromJson(dynamic json) {
    if (json is Map) {
      return Manager(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ??
            '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      );
    }

    return Manager(id: 0, name: json?.toString() ?? '');
  }
}
