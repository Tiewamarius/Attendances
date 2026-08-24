class Employee {
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

  Employee({
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

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      userId: json['user_id'],
      employeeCode: json['employee_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
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
}

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'], name: json['name'] ?? '');
  }
}

class Manager {
  final int id;
  final String name;

  Manager({required this.id, required this.name});

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(id: json['id'], name: json['name'] ?? '');
  }
}
