class AttendanceHistoryModel {
  final int id;
  final DateTime date;
  final String? arrival;
  final String? departure;
  final String total;
  final String status;

  const AttendanceHistoryModel({
    required this.id,
    required this.date,
    this.arrival,
    this.departure,
    required this.total,
    required this.status,
  });

  factory AttendanceHistoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceHistoryModel(
      id: _toInt(json['id']),

      date: _parseDate(
        json['date'] ??
            json['attendance_date'] ??
            json['created_at'],
      ),

      arrival: _nullableString(
        json['arrival'] ??
            json['arrivee'] ??
            json['check_in'],
      ),

      departure: _nullableString(
        json['departure'] ??
            json['depart'] ??
            json['check_out'],
      ),

      total: _nullableString(
            json['total'] ??
                json['duration'] ??
                json['total_hours'],
          ) ??
          '0h00',

      status: _nullableString(
            json['status'] ??
                json['state'],
          ) ??
          'Normal',
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    final stringValue = value.toString().trim();

    if (stringValue.isEmpty) {
      return DateTime.now();
    }

    return DateTime.tryParse(stringValue) ??
        DateTime.now();
  }

  // ============================================================
  // INT
  // ============================================================

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // STRING NULLABLE
  // ============================================================

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final valueString = value.toString().trim();

    if (valueString.isEmpty ||
        valueString == '-' ||
        valueString.toLowerCase() == 'null') {
      return null;
    }

    return valueString;
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'arrival': arrival,
      'departure': departure,
      'total': total,
      'status': status,
    };
  }
}