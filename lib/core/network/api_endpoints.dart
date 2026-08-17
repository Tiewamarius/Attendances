class ApiConfig {
  
  ApiConfig._();
 static const String setupAdmin ='https://ekklesiaciel.com/api/setup/admin';

  static const String baseUrl = "https://ekklesiaciel.com/api/v1";

  // AUTH
  static const String login = '$baseUrl/auth/login';

  static const String logout = '$baseUrl/auth/logout';

  static const String me = '$baseUrl/auth/me';

  // DASHBOARD
  static const String dashboard = '$baseUrl/dashboard';

  // EMPLOYEES
  static const String employees = '$baseUrl/employees';

  // ATTENDANCE
  static const String attendanceToday = '$baseUrl/attendance/today';

  static const String attendanceHistory = '$baseUrl/attendance/history';

  static const String checkIn = '$baseUrl/attendance/check-in';

  static const String checkOut = '$baseUrl/attendance/check-out';

  // PROFILE
  static const String profile = '$baseUrl/employee/profile';

  // KIOSK
  static const String kioskLogin = '$baseUrl/kiosk/login';

  static const String kioskQr = '$baseUrl/kiosk/scan-qr';

  static const String kioskPin = '$baseUrl/kiosk/check-pin';

  // LEAVES
  static const String leaves = '$baseUrl/leaves';

  static const String myLeaves = '$baseUrl/leaves/my';

  static const String leaveBalance = '$baseUrl/leaves/balance';

  // PERMISSIONS
  static const String permissions = '$baseUrl/permissions';

  static const String myPermissions = '$baseUrl/permissions/my';

  // REPORTS
  static const String reportAttendance = '$baseUrl/reports/attendance';

  // USERS
static const String users =
    '$baseUrl/users';


static String generateEmployeePin(int id) =>
    '$baseUrl/employees/$id/generate-pin';


static String generateEmployeeQr(int id) =>
    '$baseUrl/employees/$id/generate-qr';


    static String managerApproveLeave(int id) =>
    '$baseUrl/leaves/$id/manager-approve';


static String managerRejectLeave(int id) =>
    '$baseUrl/leaves/$id/manager-reject';


static String hrApproveLeave(int id) =>
    '$baseUrl/leaves/$id/hr-approve';


static String hrRejectLeave(int id) =>
    '$baseUrl/leaves/$id/hr-reject';
}
