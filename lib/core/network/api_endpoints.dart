import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // ========================================================================
  // BASE URL
  // ========================================================================

  /// Production
  static const String productionUrl =
      'https://ekklesiaciel.com/api/v1';

  /// Flutter Web en développement
  static const String webLocalUrl =
      'http://127.0.0.1:8000/api/v1';

  /// Android Emulator
  static const String androidEmulatorUrl =
      'http://10.0.2.2:8000/api/v1';

  /// Téléphone physique connecté au même réseau que le PC
  static const String physicalDeviceUrl =
      'http://192.168.1.9:8000/api/v1';

  /// URL utilisée par l'application
  static String get baseUrl {
    if (kReleaseMode) {
      return productionUrl;
    }

    if (kIsWeb) {
      return webLocalUrl;
    }

    return physicalDeviceUrl;
  }

  // ========================================================================
  // SETUP / INITIALISATION
  // ========================================================================

  /// POST /setup/organization
  static String get setupOrganization =>
      '$baseUrl/setup/organization';

  // ========================================================================
  // AUTHENTIFICATION
  // ========================================================================

  /// POST /auth/login
  static String get login =>
      '$baseUrl/auth/login';

  /// POST /auth/logout
  static String get logout =>
      '$baseUrl/auth/logout';

  /// GET /auth/dashboard
  static String get dashboard =>
      '$baseUrl/auth/dashboard';

  /// POST /auth/organization/switch
  static String get switchOrganization =>
      '$baseUrl/auth/organization/switch';

  // ========================================================================
  // PROFIL EMPLOYÉ CONNECTÉ
  // ========================================================================

  /// GET /employee/profile
  static String get employeeProfile =>
      '$baseUrl/employee/profile';

  // ========================================================================
  // POINTAGES
  // ========================================================================

  /// GET /attendance
  static String get attendance =>
      '$baseUrl/attendance';

  /// GET /attendance/{attendance}
  static String attendanceDetails(int id) =>
      '$baseUrl/attendance/$id';

  /// GET /attendance/today
  static String get attendanceToday =>
      '$baseUrl/attendance/today';

  /// GET /attendance/history
  static String get attendanceHistory =>
      '$baseUrl/attendance/history';

  /// POST /attendance/check-in
  static String get checkIn =>
      '$baseUrl/attendance/check-in';

  /// POST /attendance/check-out
  static String get checkOut =>
      '$baseUrl/attendance/check-out';

  /// POST /attendance/scan-kiosk-qr
  ///
  /// L'employé connecté scanne le QR temporaire
  /// affiché sur le Kiosk.
  static String get scanKioskAttendanceQr =>
      '$baseUrl/attendance/scan-kiosk-qr';

  // ========================================================================
  // UTILISATEURS
  // ========================================================================

  /// GET /users
  /// POST /users
  static String get users =>
      '$baseUrl/users';

  /// GET /users/{user}
  /// PUT /users/{user}
  /// DELETE /users/{user}
  static String user(int id) =>
      '$baseUrl/users/$id';

  /// GET /users/roles
  static String get roles =>
      '$baseUrl/users/roles';

  // ========================================================================
  // DÉPARTEMENTS
  // ========================================================================

  /// GET /departments
  /// POST /departments
  static String get departments =>
      '$baseUrl/departments';

  /// GET /departments/{department}
  /// PUT /departments/{department}
  /// DELETE /departments/{department}
  static String department(int id) =>
      '$baseUrl/departments/$id';

  // ========================================================================
  // EMPLOYÉS
  // ========================================================================

  /// GET /employees
  /// POST /employees
  static String get employees =>
      '$baseUrl/employees';

  /// GET /employees/{employee}
  /// PUT /employees/{employee}
  /// DELETE /employees/{employee}
  static String employee(int id) =>
      '$baseUrl/employees/$id';

  /// GET /employees/{employee}/attendance
  static String employeeAttendance(int id) =>
      '$baseUrl/employees/$id/attendance';

  /// GET /employees/{employee}/leaves
  static String employeeLeaves(int id) =>
      '$baseUrl/employees/$id/leaves';

  /// GET /employees/{employee}/permissions
  static String employeePermissions(int id) =>
      '$baseUrl/employees/$id/permissions';

  /// POST /employees/{employee}/generate-pin
  static String generateEmployeePin(int id) =>
      '$baseUrl/employees/$id/generate-pin';

  /// POST /employees/{employee}/generate-qr
  static String generateEmployeeQr(int id) =>
      '$baseUrl/employees/$id/generate-qr';

  // ========================================================================
  // KIOSKS — ADMINISTRATION
  // ========================================================================

  /*
   * Ces endpoints utilisent le token de l'utilisateur administrateur.
   *
   * Laravel :
   *
   * GET    /kiosks
   * POST   /kiosks
   * GET    /kiosks/{kiosk}
   * PUT    /kiosks/{kiosk}
   * DELETE /kiosks/{kiosk}
   * PATCH  /kiosks/{kiosk}/toggle
   * GET    /kiosks/{kiosk}/logs
   */

  /// GET /kiosks
  /// POST /kiosks
  static String get kiosks =>
      '$baseUrl/kiosks';

  /// GET /kiosks/{kiosk}
  /// PUT /kiosks/{kiosk}
  /// DELETE /kiosks/{kiosk}
  static String kiosk(int id) =>
      '$baseUrl/kiosks/$id';

  /// PATCH /kiosks/{kiosk}/toggle
  static String kioskToggle(int id) =>
      '$baseUrl/kiosks/$id/toggle';

  /// GET /kiosks/{kiosk}/logs
  static String kioskLogs(int id) =>
      '$baseUrl/kiosks/$id/logs';

  // ========================================================================
  // KIOSK — APPAREIL CONNECTÉ
  // ========================================================================

  /*
   * Ces endpoints utilisent le kiosk_token.
   *
   * Ils sont différents des endpoints /kiosks de l'administration.
   *
   * Laravel :
   *
   * POST /kiosk/login
   * GET  /kiosk/me
   * GET  /kiosk/attendance-qr
   * POST /kiosk/heartbeat
   * POST /kiosk/scan-qr
   * POST /kiosk/check-pin
   * POST /kiosk/camera-check
   */

  /// POST /kiosk/login
  static String get kioskLogin =>
      '$baseUrl/kiosk/login';

  /// GET /kiosk/me
  static String get kioskMe =>
      '$baseUrl/kiosk/me';

  /// GET /kiosk/attendance-qr
  ///
  /// Génère le QR temporaire affiché par le Kiosk.
  static String get kioskAttendanceQr =>
      '$baseUrl/kiosk/attendance-qr';

  /// POST /kiosk/heartbeat
  static String get kioskHeartbeat =>
      '$baseUrl/kiosk/heartbeat';

  /// POST /kiosk/scan-qr
  ///
  /// Le Kiosk scanne le QR permanent d'un employé.
  static String get kioskQr =>
      '$baseUrl/kiosk/scan-qr';

  /// POST /kiosk/check-pin
  ///
  /// Le Kiosk vérifie le code + PIN d'un employé.
  static String get kioskPin =>
      '$baseUrl/kiosk/check-pin';

  /// POST /kiosk/camera-check
  static String get kioskCameraCheck =>
      '$baseUrl/kiosk/camera-check';

  // ========================================================================
  // QR EMPLOYÉ
  // ========================================================================

  /// POST /qr/generate
  static String get qrGenerate =>
      '$baseUrl/qr/generate';

  /// POST /qr/refresh
  static String get qrRefresh =>
      '$baseUrl/qr/refresh';

  /// POST /qr/disable
  static String get qrDisable =>
      '$baseUrl/qr/disable';

  /// GET /qr/employees/{employee}/current
  static String employeeQrCurrent(int employeeId) =>
      '$baseUrl/qr/employees/$employeeId/current';

  /// GET /qr/employees/{employee}/history
  static String employeeQrHistory(int employeeId) =>
      '$baseUrl/qr/employees/$employeeId/history';

  // ========================================================================
  // PIN EMPLOYÉ
  // ========================================================================

  /// PUT /pin/change
  static String get pinChange =>
      '$baseUrl/pin/change';

  // ========================================================================
  // CONGÉS
  // ========================================================================

  /// GET /leaves
  /// POST /leaves
  static String get leaves =>
      '$baseUrl/leaves';

  /// GET /leaves/{leave}
  static String leave(int id) =>
      '$baseUrl/leaves/$id';

  /// GET /leaves/types
  static String get leaveTypes =>
      '$baseUrl/leaves/types';

  /// GET /leaves/balance
  static String get leaveBalance =>
      '$baseUrl/leaves/balance';

  /// GET /leaves/my
  static String get myLeaves =>
      '$baseUrl/leaves/my';

  /// POST /leaves
  static String get createLeave =>
      '$baseUrl/leaves';

  /// PUT /leaves/{id}/manager-approve
  static String managerApproveLeave(int id) =>
      '$baseUrl/leaves/$id/manager-approve';

  /// PUT /leaves/{id}/manager-reject
  static String managerRejectLeave(int id) =>
      '$baseUrl/leaves/$id/manager-reject';

  /// PUT /leaves/{id}/hr-approve
  static String hrApproveLeave(int id) =>
      '$baseUrl/leaves/$id/hr-approve';

  /// PUT /leaves/{id}/hr-reject
  static String hrRejectLeave(int id) =>
      '$baseUrl/leaves/$id/hr-reject';

  // ========================================================================
  // PERMISSIONS
  // ========================================================================

  /// GET /permissions
  /// POST /permissions
  static String get permissions =>
      '$baseUrl/permissions';

  /// GET /permissions/{permission}
  static String permission(int id) =>
      '$baseUrl/permissions/$id';

  /// GET /permissions/my
  static String get myPermissions =>
      '$baseUrl/permissions/my';

  /// POST /permissions
  static String get createPermission =>
      '$baseUrl/permissions';

  /// PUT /permissions/{id}/manager-approve
  static String managerApprovePermission(int id) =>
      '$baseUrl/permissions/$id/manager-approve';

  /// PUT /permissions/{id}/manager-reject
  static String managerRejectPermission(int id) =>
      '$baseUrl/permissions/$id/manager-reject';

  /// PUT /permissions/{id}/hr-approve
  static String hrApprovePermission(int id) =>
      '$baseUrl/permissions/$id/hr-approve';

  /// PUT /permissions/{id}/hr-reject
  static String hrRejectPermission(int id) =>
      '$baseUrl/permissions/$id/hr-reject';

  // ========================================================================
  // RAPPORTS RH
  // ========================================================================

  /// GET /reports/dashboard
  static String get reportDashboard =>
      '$baseUrl/reports/dashboard';

  /// GET /reports/attendance
  static String get reportAttendance =>
      '$baseUrl/reports/attendance';

  /// GET /reports/attendance/export
  static String get reportAttendanceExport =>
      '$baseUrl/reports/attendance/export';

  /// GET /reports/leaves
  static String get reportLeaves =>
      '$baseUrl/reports/leaves';

  /// GET /reports/leaves/export
  static String get reportLeavesExport =>
      '$baseUrl/reports/leaves/export';

  /// GET /reports/permissions
  static String get reportPermissions =>
      '$baseUrl/reports/permissions';
}