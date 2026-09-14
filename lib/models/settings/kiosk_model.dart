class KioskModel {
  final int id;
  final String name;
  final String? code;
  final String? location;
  final String method;
  final String? apiKey;
  final String? ipAddress;
  final bool active;
  final String? lastConnection;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  const KioskModel({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.method = 'KIOSK_QR',
    this.apiKey,
    this.ipAddress,
    this.active = true,
    this.lastConnection,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory KioskModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return KioskModel(
      id: _toInt(json['id']) ?? 0,
      name: _string(json['name']),
      code: _nullable(json['code']),
      location: _nullable(json['location']),
      method:
          _string(
            json['method'],
            fallback: 'KIOSK_QR',
          ),
      apiKey: _nullable(
        json['api_key'] ??
            json['apiKey'],
      ),
      ipAddress: _nullable(
        json['ip_address'] ??
            json['ipAddress'],
      ),
      active: _toBool(
        json['active'],
        fallback: true,
      ),
      lastConnection: _nullable(
        json['last_connection'] ??
            json['lastConnection'],
      ),
      organizationId: _toInt(
        json['organization_id'] ??
            json['organizationId'],
      ),
      createdAt: _nullable(
        json['created_at'],
      ),
      updatedAt: _nullable(
        json['updated_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'method': method,
      'api_key': apiKey,
      'ip_address': ipAddress,
      'active': active,
      'last_connection': lastConnection,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty ||
        result == 'null') {
      return fallback;
    }

    return result;
  }

  static String? _nullable(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    if (result.isEmpty ||
        result == 'null') {
      return null;
    }

    return result;
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

    if (value is int) return value == 1;

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