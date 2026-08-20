class ApiConfig {
  ApiConfig._();


static const String adminMe = '$baseUrl/auth/me';

static const String adminUpdate = '$baseUrl/admin/update';

static const String departments = '$baseUrl/departments';

static String department(int id) =>
    '$baseUrl/departments/$id';

static const String roles = '$baseUrl/roles';

static const String kiosks = '$baseUrl/kiosks';

static String kiosk(int id) =>
    '$baseUrl/kiosks/$id';

static String kioskToggle(int id) =>
    '$baseUrl/kiosks/$id/toggle';


  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'https://ekklesiaciel.com/api/v1';

  // ============================================================
  // SETUP / ADMINISTRATION INITIALE
  // ============================================================

  static const String setupAdmin = 'https://ekklesiaciel.com/api/setup/admin';

  // ============================================================
  // ADMIN
  // ============================================================

  // -------------------------
  // Authentification Admin
  // -------------------------

  static const String adminLogin = '$baseUrl/auth/login';

  static const String adminLogout = '$baseUrl/auth/logout';

  // -------------------------
  // Dashboard Admin
  // -------------------------

  static const String adminDashboard = '$baseUrl/dashboard';

  // -------------------------
  // Utilisateurs
  // -------------------------

  static const String users = '$baseUrl/users';

  // -------------------------
  // Employés - Administration
  // -------------------------

  static const String employees = '$baseUrl/employees';

  static String employee(int id) => '$baseUrl/employees/$id';

  static String generateEmployeePin(int id) =>
      '$baseUrl/employees/$id/generate-pin';

  static String generateEmployeeQr(int id) =>
      '$baseUrl/employees/$id/generate-qr';

  // -------------------------
  // Congés - Administration & RH
  // -------------------------

  static const String leaves = '$baseUrl/leaves';

  static String managerApproveLeave(int id) =>
      '$baseUrl/leaves/$id/manager-approve';

  static String managerRejectLeave(int id) =>
      '$baseUrl/leaves/$id/manager-reject';

  static String hrApproveLeave(int id) => '$baseUrl/leaves/$id/hr-approve';

  static String hrRejectLeave(int id) => '$baseUrl/leaves/$id/hr-reject';

  // -------------------------
  // Permissions
  // -------------------------

  static const String permissions = '$baseUrl/permissions';

  // -------------------------
  // Rapports
  // -------------------------

  static const String reportAttendance = '$baseUrl/reports/attendance';

  // ============================================================
  // EMPLOYEE
  // ============================================================

  // -------------------------
  // Profil
  // -------------------------

  static const String employeeProfile = '$baseUrl/employee/profile';

  // -------------------------
  // Présence
  // -------------------------

  static const String attendanceToday = '$baseUrl/attendance/today';

  static const String attendanceHistory = '$baseUrl/attendance/history';

  static const String checkIn = '$baseUrl/attendance/check-in';

  static const String checkOut = '$baseUrl/attendance/check-out';

  // -------------------------
  // Congés
  // -------------------------

  static const String myLeaves = '$baseUrl/leaves/my';

  static const String leaveBalance = '$baseUrl/leaves/balance';

  // -------------------------
  // Permissions
  // -------------------------

  static const String myPermissions = '$baseUrl/permissions/my';



  // -------------------------
  // Authentification Kiosk
  // -------------------------

  static const String kioskLogin = '$baseUrl/kiosk/login';

  // -------------------------
  // Scan / QR / PIN
  // -------------------------

  static const String kioskQr = '$baseUrl/kiosk/scan-qr';

  static const String kioskPin = '$baseUrl/kiosk/check-pin';
}
