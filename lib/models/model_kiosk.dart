class KioskModel {
  final int id;
  final String name;
  final String code;
  final String location;
  final String method;
  final String ipAddress;
  final bool active;
  final String lastConnection;

  KioskModel({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.method,
    required this.ipAddress,
    required this.active,
    required this.lastConnection,
  });

  factory KioskModel.fromJson(Map<String, dynamic> json) {
    return KioskModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Kiosk',
      code: json['code']?.toString() ?? '-',
      location: json['location']?.toString() ?? '-',
      method: json['method']?.toString() ?? '-',
      ipAddress: json['ip_address']?.toString() ?? '-',
      active: json['active'] == true || json['active'] == 1,
      lastConnection:
          json['last_connection']?.toString() ?? 'Jamais',
    );
  }
}