import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // BASE URL
  static const String productionUrl =
      'https://ekklesiaciel.com/api/v1';

  static const String webLocalUrl =
      'http://127.0.0.1:8000/api/v1';

  static const String androidEmulatorUrl =
      'http://10.0.2.2:8000/api/v1';

  static const String physicalDeviceUrl =
      'http://192.168.1.8:8000/api/v1';

  static String get baseUrl {
    if (kReleaseMode) {
      return productionUrl;
    }

    if (kIsWeb) {
      return webLocalUrl;
    }

    return physicalDeviceUrl;
  }

  // SETUP
  static String get setupOrganization =>
      '$baseUrl/setup/organization';

  // AUTH
  static String get login =>
      '$baseUrl/auth/login';

  static String get logout =>
      '$baseUrl/auth/logout';

  static String get switchOrganization =>
      '$baseUrl/auth/organization/switch';

  static String get dashboard =>
      '$baseUrl/auth/dashboard';

  // USER ADMIN
  static String get currentUserAdmin =>
      '$baseUrl/users/me';

  static String get adminCurrentUser =>
      currentUserAdmin;

  static String get users =>
      '$baseUrl/users';

  static String user(int id) =>
      '$baseUrl/users/$id';

  static String get roles =>
      '$baseUrl/users/roles';

  // EMPLOYEE PROFILE
  static String get employeeProfile =>
      '$baseUrl/employee/profile';

  // ATTENDANCE
  static String get attendance =>
      '$baseUrl/attendance';

  static String attendanceDetails(int id) =>
      '$baseUrl/attendance/$id';

  static String get checkIn =>
      '$baseUrl/attendance/check-in';

  static String get checkOut =>
      '$baseUrl/attendance/check-out';

  static String get attendanceToday =>
      '$baseUrl/attendance/today';

  static String get attendanceHistory =>
      '$baseUrl/attendance/history';

  static String get scanKioskAttendanceQr =>
      '$baseUrl/attendance/scan-kiosk-qr';

  // DEPARTMENTS
  static String get departments =>
      '$baseUrl/departments';

  static String department(int id) =>
      '$baseUrl/departments/$id';

  // EMPLOYEES ADMIN
  static String get employees =>
      '$baseUrl/employees';

  static String employee(int id) =>
      '$baseUrl/employees/$id';

  static String employeeAttendance(int id) =>
      '$baseUrl/employees/$id/attendance';

  static String employeeLeaves(int id) =>
      '$baseUrl/employees/$id/leaves';

  static String employeePermissions(int id) =>
      '$baseUrl/employees/$id/permissions';

  static String generateEmployeePin(int id) =>
      '$baseUrl/employees/$id/generate-pin';

  static String generateEmployeeQr(int id) =>
      '$baseUrl/employees/$id/generate-qr';

  // KIOSKS ADMIN
  static String get kiosks =>
      '$baseUrl/kiosks';

  static String kiosk(int id) =>
      '$baseUrl/kiosks/$id';

  static String kioskToggle(int id) =>
      '$baseUrl/kiosks/$id/toggle';

  static String kioskLogs(int id) =>
      '$baseUrl/kiosks/$id/logs';

  // KIOSK CONNECTÉ
  static String get kioskLogin =>
      '$baseUrl/kiosk/login';

  static String get kioskMe =>
      '$baseUrl/kiosk/me';

  static String get kioskAttendanceQr =>
      '$baseUrl/kiosk/attendance-qr';

  static String get kioskHeartbeat =>
      '$baseUrl/kiosk/heartbeat';

  static String get kioskScanQr =>
      '$baseUrl/kiosk/scan-qr';

  static String get kioskCheckPin =>
      '$baseUrl/kiosk/check-pin';

  static String get kioskCameraCheck =>
      '$baseUrl/kiosk/camera-check';

  // Compatibilité
  static String get kioskQr =>
      kioskScanQr;

  static String get kioskPin =>
      kioskCheckPin;

  // QR EMPLOYÉ
  static String get qrGenerate =>
      '$baseUrl/qr/generate';

  static String get qrRefresh =>
      '$baseUrl/qr/refresh';

  static String get qrDisable =>
      '$baseUrl/qr/disable';

  static String employeeQrCurrent(int employeeId) =>
      '$baseUrl/qr/employees/$employeeId/current';

  static String employeeQrHistory(int employeeId) =>
      '$baseUrl/qr/employees/$employeeId/history';

  // PIN
  static String get pinChange =>
      '$baseUrl/pin/change';

  // LEAVES
  static String get leaves =>
      '$baseUrl/leaves';

  static String get leaveTypes =>
      '$baseUrl/leaves/types';

  static String get leaveBalance =>
      '$baseUrl/leaves/balance';

  static String get myLeaves =>
      '$baseUrl/leaves/my';

  static String leave(int id) =>
      '$baseUrl/leaves/$id';

  static String managerApproveLeave(int id) =>
      '$baseUrl/leaves/$id/manager-approve';

  static String managerRejectLeave(int id) =>
      '$baseUrl/leaves/$id/manager-reject';

  static String hrApproveLeave(int id) =>
      '$baseUrl/leaves/$id/hr-approve';

  static String hrRejectLeave(int id) =>
      '$baseUrl/leaves/$id/hr-reject';

  // PERMISSIONS
  static String get permissions =>
      '$baseUrl/permissions';

  static String get myPermissions =>
      '$baseUrl/permissions/my';

  static String permission(int id) =>
      '$baseUrl/permissions/$id';

  static String managerApprovePermission(int id) =>
      '$baseUrl/permissions/$id/manager-approve';

  static String managerRejectPermission(int id) =>
      '$baseUrl/permissions/$id/manager-reject';

  static String hrApprovePermission(int id) =>
      '$baseUrl/permissions/$id/hr-approve';

  static String hrRejectPermission(int id) =>
      '$baseUrl/permissions/$id/hr-reject';

  // REPORTS
  static String get reportDashboard =>
      '$baseUrl/reports/dashboard';

  static String get reportAttendance =>
      '$baseUrl/reports/attendance';

  static String get reportAttendanceExport =>
      '$baseUrl/reports/attendance/export';

  static String get reportLeaves =>
      '$baseUrl/reports/leaves';

  static String get reportLeavesExport =>
      '$baseUrl/reports/leaves/export';

  static String get reportPermissions =>
      '$baseUrl/reports/permissions';
}