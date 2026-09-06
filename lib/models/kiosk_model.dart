class KioskModel {
  final int id;
  final String name;
  final String code;

  final String? location;

  final String mode;

  // Conservé uniquement pour compatibilité
  // avec les réponses administratives.
  //
  // Le login Kiosk ne l'utilise plus.
  final String? apiKey;

  final String? ipAddress;

  final bool active;

  final String? lastConnection;

  final String? deviceId;
  final String? deviceName;
  final String? deviceModel;

  final String? platform;
  final String? appVersion;

  final String? activatedAt;

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
    this.deviceId,
    this.deviceName,
    this.deviceModel,
    this.platform,
    this.appVersion,
    this.activatedAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory KioskModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final parsedMode =
        _parseString(json['mode']);

    return KioskModel(
      id: _parseInt(json['id']),

      name: _parseString(
        json['name'],
      ),

      code: _parseString(
        json['code'],
      ),

      location: _parseNullableString(
        json['location'],
      ),

      mode: parsedMode.isEmpty
          ? 'KIOSK_QR'
          : parsedMode,

      apiKey: _parseNullableString(
        json['api_key'],
      ),

      ipAddress: _parseNullableString(
        json['ip_address'],
      ),

      active: _parseBool(
        json['active'],
      ),

      lastConnection:
          _parseNullableString(
        json['last_connection'],
      ),

      deviceId:
          _parseNullableString(
        json['device_id'],
      ),

      deviceName:
          _parseNullableString(
        json['device_name'],
      ),

      deviceModel:
          _parseNullableString(
        json['device_model'],
      ),

      platform:
          _parseNullableString(
        json['platform'],
      ),

      appVersion:
          _parseNullableString(
        json['app_version'],
      ),

      activatedAt:
          _parseNullableString(
        json['activated_at'],
      ),
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  String get displayName {
    if (location != null &&
        location!.isNotEmpty) {
      return '$name • $location';
    }

    return name;
  }

  bool get isActive => active;

  bool get isActivated =>
      deviceId != null &&
      deviceId!.isNotEmpty;

  bool get hasApiKey =>
      apiKey != null &&
      apiKey!.isNotEmpty;

  bool get isQrMode =>
      mode == 'KIOSK_QR';

  bool get isPinMode =>
      mode == 'KIOSK_PIN';

  bool get isMobileMode =>
      mode == 'MOBILE';

  bool get isManualMode =>
      mode == 'MANUAL';

  // ============================================================
  // PARSERS
  // ============================================================

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static String _parseString(
    dynamic value,
  ) {
    return value
            ?.toString()
            .trim() ??
        '';
  }

  static String? _parseNullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final valueString =
        value.toString().trim();

    if (valueString.isEmpty ||
        valueString.toLowerCase() ==
            'null') {
      return null;
    }

    return valueString;
  }

  static bool _parseBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized =
          value.toLowerCase().trim();

      return normalized == '1' ||
          normalized == 'true';
    }

    return false;
  }

  // ============================================================
  // TOSTRING
  // ============================================================

  @override
  String toString() {
    return 'KioskModel('
        'id: $id, '
        'name: $name, '
        'code: $code, '
        'mode: $mode, '
        'active: $active, '
        'deviceId: $deviceId'
        ')';
  }
}