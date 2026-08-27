class EmployeeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? position;
  final String? profileImage;
  final String? qrToken;

  const EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.position,
    this.profileImage,
    this.qrToken,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final qrValue =
        json['qr_token'] ??
        json['qrToken'] ??
        json['qr'];

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

      qrToken: _parseQrToken(qrValue),
    );
  }

  // ============================================================
  // NOM COMPLET
  // ============================================================

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  // ============================================================
  // INITIALES
  // ============================================================

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

  // ============================================================
  // QR DISPONIBLE ?
  // ============================================================

  bool get hasQrToken {
    return qrToken != null && qrToken!.trim().isNotEmpty;
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // STRING
  // ============================================================

  static String _parseString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // STRING NULLABLE
  // ============================================================

  static String? _parseNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  // ============================================================
  // QR TOKEN
  // ============================================================

  static String? _parseQrToken(dynamic value) {
    if (value == null) {
      return null;
    }

    // ----------------------------------------------------------
    // CAS 1 : QR directement sous forme String
    // ----------------------------------------------------------
    //
    // "qr_token": "abc123"
    //

    if (value is String) {
      final token = value.trim();

      if (token.isEmpty || token.toLowerCase() == 'null') {
        return null;
      }

      return token;
    }

    // ----------------------------------------------------------
    // CAS 2 : QR sous forme Map
    // ----------------------------------------------------------
    //
    // "qr_token": {
    //     "id": 2,
    //     "employee_id": 2,
    //     "token": "abc123",
    //     ...
    // }
    //

    if (value is Map) {
      final token = value['token'];

      if (token == null) {
        return null;
      }

      final result = token.toString().trim();

      if (result.isEmpty || result.toLowerCase() == 'null') {
        return null;
      }

      return result;
    }

    return null;
  }
}