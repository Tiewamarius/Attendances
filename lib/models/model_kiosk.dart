class KioskModel {
  final int id;
  final String name;
  final String code;
  final String? location;
  final String mode;
  final String? apiKey;
  final String? ipAddress;
  final bool active;
  final DateTime? lastConnection;

  const KioskModel({
    required this.id,
    required this.name,
    required this.code,
    this.location,
    required this.mode,
    this.apiKey,
    this.ipAddress,
    required this.active,
    this.lastConnection,
  });

  factory KioskModel.fromJson(Map<String, dynamic> json) {
    return KioskModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      name: json['name']?.toString() ?? '',

      code: json['code']?.toString() ?? '',

      location: json['location']?.toString(),

      mode: json['mode']?.toString() ?? 'qr_pin',

      apiKey: json['api_key']?.toString(),

      ipAddress: json['ip_address']?.toString(),

      active:
          json['active'] == true ||
          json['active'] == 1 ||
          json['active']?.toString() == '1',

      lastConnection: json['last_connection'] != null
          ? DateTime.tryParse(json['last_connection'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'mode': mode,
      'api_key': apiKey,
      'ip_address': ipAddress,
      'active': active,
      'last_connection': lastConnection?.toIso8601String(),
    };
  }
}
