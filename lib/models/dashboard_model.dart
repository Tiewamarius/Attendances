class DashboardModel {
  final OrganizationDashboard organization;
  final DashboardUser user;
  final List<String> roles;
  final List<String> permissions;
  final DashboardStatistics statistics;
  final RecentActivity recentActivity;
  final DashboardEmployee? employee;

  const DashboardModel({
    required this.organization,
    required this.user,
    required this.roles,
    required this.permissions,
    required this.statistics,
    required this.recentActivity,
    this.employee,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      organization: OrganizationDashboard.fromJson(
        json['organization'] as Map<String, dynamic>,
      ),
      user: DashboardUser.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
      roles: List<String>.from(json['roles'] ?? const []),
      permissions: List<String>.from(json['permissions'] ?? const []),
      statistics: DashboardStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
      recentActivity: RecentActivity.fromJson(
        json['recent_activity'] as Map<String, dynamic>,
      ),
      employee: json['employee'] != null
          ? DashboardEmployee.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class OrganizationDashboard {
  final int id;
  final String name;
  final String slug;
  final String? email;
  final String? phone;
  final String country;
  final String timezone;
  final bool active;

  const OrganizationDashboard({
    required this.id,
    required this.name,
    required this.slug,
    this.email,
    this.phone,
    required this.country,
    required this.timezone,
    required this.active,
  });

  factory OrganizationDashboard.fromJson(Map<String, dynamic> json) {
    return OrganizationDashboard(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
      active: json['active'] as bool? ?? false,
    );
  }
}

class DashboardUser {
  final int id;
  final String name;
  final String email;
  final bool active;
  final String? lastLoginAt;

  const DashboardUser({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
    this.lastLoginAt,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }
}

class DashboardStatistics {
  final EmployeeStatistics employees;
  final DepartmentStatistics departments;
  final KioskStatistics kiosks;
  final AttendanceStatistics attendance;
  final LeaveStatistics leaves;

  const DashboardStatistics({
    required this.employees,
    required this.departments,
    required this.kiosks,
    required this.attendance,
    required this.leaves,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      employees: EmployeeStatistics.fromJson(
        json['employees'] as Map<String, dynamic>,
      ),
      departments: DepartmentStatistics.fromJson(
        json['departments'] as Map<String, dynamic>,
      ),
      kiosks: KioskStatistics.fromJson(
        json['kiosks'] as Map<String, dynamic>,
      ),
      attendance: AttendanceStatistics.fromJson(
        json['attendance'] as Map<String, dynamic>,
      ),
      leaves: LeaveStatistics.fromJson(
        json['leaves'] as Map<String, dynamic>,
      ),
    );
  }
}

class EmployeeStatistics {
  final int total;
  final int active;

  const EmployeeStatistics({
    required this.total,
    required this.active,
  });

  factory EmployeeStatistics.fromJson(Map<String, dynamic> json) {
    return EmployeeStatistics(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
    );
  }
}

class DepartmentStatistics {
  final int total;
  final int active;

  const DepartmentStatistics({
    required this.total,
    required this.active,
  });

  factory DepartmentStatistics.fromJson(Map<String, dynamic> json) {
    return DepartmentStatistics(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
    );
  }
}

class KioskStatistics {
  final int total;
  final int active;

  const KioskStatistics({
    required this.total,
    required this.active,
  });

  factory KioskStatistics.fromJson(Map<String, dynamic> json) {
    return KioskStatistics(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
    );
  }
}

class AttendanceStatistics {
  final int presentToday;
  final int absentToday;
  final int lateToday;

  const AttendanceStatistics({
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    return AttendanceStatistics(
      presentToday: json['present_today'] as int? ?? 0,
      absentToday: json['absent_today'] as int? ?? 0,
      lateToday: json['late_today'] as int? ?? 0,
    );
  }
}

class LeaveStatistics {
  final int inProgress;

  const LeaveStatistics({
    required this.inProgress,
  });

  factory LeaveStatistics.fromJson(Map<String, dynamic> json) {
    return LeaveStatistics(
      inProgress: json['in_progress'] as int? ?? 0,
    );
  }
}

class RecentActivity {
  final List<dynamic> attendances;
  final List<dynamic> employees;

  const RecentActivity({
    required this.attendances,
    required this.employees,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      attendances: List<dynamic>.from(
        json['attendances'] ?? const [],
      ),
      employees: List<dynamic>.from(
        json['employees'] ?? const [],
      ),
    );
  }
}

class DashboardEmployee {
  const DashboardEmployee();

  factory DashboardEmployee.fromJson(Map<String, dynamic> json) {
    return const DashboardEmployee();
  }
}