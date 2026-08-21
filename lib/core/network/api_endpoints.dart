import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // ============================================================
  // BASE URL
  // ============================================================

  static const String productionUrl =
      'https://ekklesiaciel.com/api/v1';

  static const String webLocalUrl =
      'http://127.0.0.1:8000/api/v1';

  static const String androidEmulatorUrl =
      'http://10.0.2.2:8000/api/v1';

  // Remplace cette adresse par l'adresse IP locale de ton PC.
  static const String physicalDeviceUrl =
      'http://192.168.1.100:8000/api/v1';

  // Retourne l'URL adaptée à l'environnement.
  static String get baseUrl {
    if (kReleaseMode) {
      return productionUrl;
    }

    if (kIsWeb) {
      return webLocalUrl;
    }

    return physicalDeviceUrl;
  }

  // ============================================================
  // SETUP / INSTALLATION INITIALE
  // ============================================================

  static String get setupRoles =>
      '$baseUrl/setup/roles';

  static String get setupAdmin =>
      '$baseUrl/setup/admin';

  // ============================================================
  // AUTHENTIFICATION
  // ============================================================

  static String get login =>
      '$baseUrl/auth/login';

  static String get logout =>
      '$baseUrl/auth/logout';

  static String get me =>
      '$baseUrl/auth/me';

  // ============================================================
  // DASHBOARD
  // ============================================================

  static String get dashboard =>
      '$baseUrl/dashboard';

  // ============================================================
  // UTILISATEURS
  // ============================================================

  static String get users =>
      '$baseUrl/users';

  static String user(int id) =>
      '$baseUrl/users/$id';

  // ============================================================
  // DEPARTEMENTS
  // ============================================================

  static String get departments =>
      '$baseUrl/departments';

  // Détail d'un département.

  static String department(int id) =>
      '$baseUrl/departments/$id';

  // ============================================================
  // ROLES
  // ============================================================

  // Tous les rôles.

  static String get roles =>
      '$baseUrl/roles';

  // Détail d'un rôle.

  static String role(int id) =>
      '$baseUrl/roles/$id';

  // Supprimer un rôle.

  static String roleDelete(int id) =>
      '$baseUrl/roles/$id';

  // ============================================================
  // EMPLOYES - ADMINISTRATION RH
  // ============================================================

  static String get employees =>
      '$baseUrl/employees';

  static String employee(int id) =>
      '$baseUrl/employees/$id';

  // Informations d'un employé.

  static String employeeAttendance(int id) =>
      '$baseUrl/employees/$id/attendance';

  static String employeeLeaves(int id) =>
      '$baseUrl/employees/$id/leaves';

  static String employeePermissions(int id) =>
      '$baseUrl/employees/$id/permissions';

  // Générer le PIN d'un employé.

  static String generateEmployeePin(int id) =>
      '$baseUrl/employees/$id/generate-pin';

  // Générer le QR d'un employé.

  static String generateEmployeeQr(int id) =>
      '$baseUrl/employees/$id/generate-qr';

  // ============================================================
  // PROFIL EMPLOYE CONNECTE
  // ============================================================

  static String get employeeProfile =>
      '$baseUrl/employee/profile';

  // ============================================================
  // POINTAGES
  // ============================================================

  // Tous les pointages.

  static String get attendance =>
      '$baseUrl/attendance';

  // Détail d'un pointage.

  static String attendanceDetails(int id) =>
      '$baseUrl/attendance/$id';

  // Pointage du jour.

  static String get attendanceToday =>
      '$baseUrl/attendance/today';

  // Historique des pointages.

  static String get attendanceHistory =>
      '$baseUrl/attendance/history';

  // Check-in.

  static String get checkIn =>
      '$baseUrl/attendance/check-in';

  // Check-out.

  static String get checkOut =>
      '$baseUrl/attendance/check-out';

  // ============================================================
  // KIOSKS - ADMINISTRATION
  // ============================================================

  static String get kiosks =>
      '$baseUrl/kiosks';

  // Détail d'un kiosk.

  static String kiosk(int id) =>
      '$baseUrl/kiosks/$id';

  // Logs d'un kiosk.

  static String kioskLogs(int id) =>
      '$baseUrl/kiosks/$id/logs';

  // Activer ou désactiver un kiosk.

  static String kioskToggle(int id) =>
      '$baseUrl/kiosks/$id/toggle';

  // ============================================================
  // KIOSK - AUTHENTIFICATION
  // ============================================================

  static String get kioskLogin =>
      '$baseUrl/kiosk/login';

  // ============================================================
  // KIOSK - OPERATIONS
  // ============================================================

  // Heartbeat du kiosk.

  static String get kioskHeartbeat =>
      '$baseUrl/kiosk/heartbeat';

  // Scan QR depuis le kiosk.

  static String get kioskQr =>
      '$baseUrl/kiosk/scan-qr';

  // Vérification PIN depuis le kiosk.

  static String get kioskPin =>
      '$baseUrl/kiosk/check-pin';

  // Vérification caméra.

  static String get kioskCameraCheck =>
      '$baseUrl/kiosk/camera-check';

  // ============================================================
  // QR EMPLOYE
  // ============================================================

  // Générer un QR.

  static String get qrGenerate =>
      '$baseUrl/qr/generate';

  // Rafraîchir un QR.

  static String get qrRefresh =>
      '$baseUrl/qr/refresh';

  // Désactiver un QR.

  static String get qrDisable =>
      '$baseUrl/qr/disable';

  // ============================================================
  // PIN EMPLOYE
  // ============================================================

  // Modifier le PIN.

  static String get pinChange =>
      '$baseUrl/pin/change';

  // ============================================================
  // CONGES
  // ============================================================

  // Toutes les demandes de congé.

  static String get leaves =>
      '$baseUrl/leaves';

  // Détail d'un congé.

  static String leave(int id) =>
      '$baseUrl/leaves/$id';

  // Types de congés.

  static String get leaveTypes =>
      '$baseUrl/leaves/types';

  // Solde de congés.

  static String get leaveBalance =>
      '$baseUrl/leaves/balance';

  // Mes congés.

  static String get myLeaves =>
      '$baseUrl/leaves/my';

  // Créer une demande de congé.

  static String get createLeave =>
      '$baseUrl/leaves';

  // Validation Manager.

  static String managerApproveLeave(int id) =>
      '$baseUrl/leaves/$id/manager-approve';

  static String managerRejectLeave(int id) =>
      '$baseUrl/leaves/$id/manager-reject';

  // Validation RH.

  static String hrApproveLeave(int id) =>
      '$baseUrl/leaves/$id/hr-approve';

  static String hrRejectLeave(int id) =>
      '$baseUrl/leaves/$id/hr-reject';

  // ============================================================
  // PERMISSIONS
  // ============================================================

  // Toutes les demandes de permission.

  static String get permissions =>
      '$baseUrl/permissions';

  // Détail d'une permission.

  static String permission(int id) =>
      '$baseUrl/permissions/$id';

  // Mes permissions.

  static String get myPermissions =>
      '$baseUrl/permissions/my';

  // Créer une demande de permission.

  static String get createPermission =>
      '$baseUrl/permissions';

  // Validation Manager.

  static String managerApprovePermission(int id) =>
      '$baseUrl/permissions/$id/manager-approve';

  static String managerRejectPermission(int id) =>
      '$baseUrl/permissions/$id/manager-reject';

  // Validation RH.

  static String hrApprovePermission(int id) =>
      '$baseUrl/permissions/$id/hr-approve';

  static String hrRejectPermission(int id) =>
      '$baseUrl/permissions/$id/hr-reject';

  // ============================================================
  // RAPPORTS RH
  // ============================================================

  // Dashboard des rapports.

  static String get reportDashboard =>
      '$baseUrl/reports/dashboard';

  // Rapport des pointages.

  static String get reportAttendance =>
      '$baseUrl/reports/attendance';

  // Export des pointages.

  static String get reportAttendanceExport =>
      '$baseUrl/reports/attendance/export';

  // Rapport des congés.

  static String get reportLeaves =>
      '$baseUrl/reports/leaves';

  // Export des congés.

  static String get reportLeavesExport =>
      '$baseUrl/reports/leaves/export';

  // Rapport des permissions.

  static String get reportPermissions =>
      '$baseUrl/reports/permissions';
}