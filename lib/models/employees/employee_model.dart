class EmployeeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? position;
  final String? profileImage;

  const EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.position,
    this.profileImage,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: _parseInt(json['id']),
      firstName: _parseString(
        json['first_name'] ??
            json['firstName'] ??
            json['firstname'],
      ),
      lastName: _parseString(
        json['last_name'] ??
            json['lastName'] ??
            json['lastname'],
      ),
      email: _parseString(json['email']),
      phone: _parseNullableString(
        json['phone'] ??
            json['telephone'] ??
            json['phone_number'],
      ),
      position: _parseNullableString(
        json['position'] ??
            json['job_title'] ??
            json['poste'],
      ),
      profileImage: _parseNullableString(
        json['profile_image'] ??
            json['profileImage'] ??
            json['avatar'] ??
            json['photo'],
      ),
    );
  }

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();

    if (first.isEmpty && last.isEmpty) {
      return '?';
    }

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }

    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }

    return last[0].toUpperCase();
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _parseString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') {
      return null;
    }

    return result;
  }
}