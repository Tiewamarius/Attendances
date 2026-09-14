class DepartmentModel {
  final int id;
  final String name;
  final String? description;
  final bool active;
  final int employeesCount;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.active = true,
    this.employeesCount = 0,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: _toInt(json['id']) ?? 0,
      name: _toString(json['name']),
      description: _nullableString(json['description']),
      active: _toBool(json['active'], fallback: true),
      employeesCount:
          _toInt(
            json['employees_count'] ??
                json['employeesCount'] ??
                json['employees_count_total'],
          ) ??
          0,
      organizationId:
          _toInt(
            json['organization_id'] ??
                json['organizationId'],
          ),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'employees_count': employeesCount,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DepartmentModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? active,
    int? employeesCount,
    int? organizationId,
    String? createdAt,
    String? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      employeesCount:
          employeesCount ?? this.employeesCount,
      organizationId:
          organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final valueString = value.toString().trim();

    if (valueString.isEmpty ||
        valueString == 'null') {
      return null;
    }

    return valueString;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static bool _toBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is int) {
      return value == 1;
    }

    final text =
        value.toString().toLowerCase().trim();

    if (text == 'true' ||
        text == '1' ||
        text == 'active') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'inactive') {
      return false;
    }

    return fallback;
  }
}