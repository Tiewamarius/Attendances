class AdminDashboardModel {
  final DashboardStats stats;
  final List<PendingRequestModel> pendingRequests;

  AdminDashboardModel({
    required this.stats,
    required this.pendingRequests,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      stats: DashboardStats.fromJson(
        json['stats'] ?? {},
      ),
      pendingRequests: (json['pending_requests'] as List? ?? [])
          .map(
            (item) => PendingRequestModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class DashboardStats {
  final int totalEmployees;
  final int present;
  final int remote;
  final int absent;
  final int late;

  DashboardStats({
    required this.totalEmployees,
    required this.present,
    required this.remote,
    required this.absent,
    required this.late,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEmployees: json['total_employees'] ?? 0,
      present: json['present'] ?? 0,
      remote: json['remote'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
    );
  }
}

class PendingRequestModel {
  final int id;
  final String employeeName;
  final String position;
  final String type;
  final String startDate;
  final String endDate;

  PendingRequestModel({
    required this.id,
    required this.employeeName,
    required this.position,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory PendingRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final employee = json['employee'] ?? {};

    final firstName = employee['first_name'] ?? '';
    final lastName = employee['last_name'] ?? '';

    return PendingRequestModel(
      id: json['id'] ?? 0,
      employeeName: '$firstName $lastName'.trim(),
      position: employee['position'] ?? '',
      type: json['type'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}