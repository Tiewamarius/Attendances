class LeaveModel {
  final int id;

  final String employeeName;
  final String employeeInitials;

  final String leaveType;

  final DateTime? startDate;
  final DateTime? endDate;

  final int totalDays;

  final String reason;

  final String status;

  LeaveModel({
    required this.id,
    required this.employeeName,
    required this.employeeInitials,
    required this.leaveType,
    this.startDate,
    this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'])
        : <String, dynamic>{};

    final user = employee['user'] is Map
        ? Map<String, dynamic>.from(employee['user'])
        : <String, dynamic>{};

    final name =
        user['name']?.toString() ??
        employee['name']?.toString() ??
        json['employee_name']?.toString() ??
        'Employé';

    return LeaveModel(
      id: _parseInt(json['id']),

      employeeName: name,

      employeeInitials: _getInitials(name),

      leaveType:
          json['leave_type']?.toString() ??
          json['type']?.toString() ??
          json['type_name']?.toString() ??
          'Congé',

      startDate: _parseDate(
        json['start_date'] ??
            json['date_start'] ??
            json['date_debut'],
      ),

      endDate: _parseDate(
        json['end_date'] ??
            json['date_end'] ??
            json['date_fin'],
      ),

      totalDays: _parseInt(
        json['total_days'] ??
            json['days'] ??
            json['nombre_jours'] ??
            0,
      ),

      reason:
          json['reason']?.toString() ??
          json['motif']?.toString() ??
          '',

      status:
          json['status']?.toString() ??
          json['statut']?.toString() ??
          'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_name': employeeName,
      'leave_type': leaveType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
    };
  }

  bool get isPending {
    return status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'en_attente' ||
        status.toLowerCase() == 'attente';
  }

  bool get isApproved {
    return status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'approuve' ||
        status.toLowerCase() == 'approuvé';
  }

  bool get isRejected {
    return status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'refuse' ||
        status.toLowerCase() == 'refusé';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}