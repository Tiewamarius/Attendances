import 'package:attendance/models/model_roles.dart';
import 'package:flutter/foundation.dart';

import 'package:attendance/models/model_department.dart';
import 'package:attendance/models/model_kiosk.dart';
import 'package:attendance/services/admin_service.dart';
import 'package:attendance/services/kiosk_service.dart';

class AdminSettingsController extends ChangeNotifier {
  // ============================================================
  // DATA
  // ============================================================

  dynamic profile;

  List<DepartmentModel> departments = [];

  List<RoleModel> roles = [];

  List<KioskModel> kiosks = [];

  // ============================================================
  // STATES
  // ============================================================

  bool loading = false;

  bool kioskLoading = false;

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  Future<void> loadInitialData() async {
    loading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadProfile(),
        loadDepartments(),
        loadRoles(),
        loadKiosks(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement paramètres : $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    profile = await AdminService.getProfile();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    await AdminService.updateProfile(name: name, email: email);

    await loadProfile();
  }

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  Future<void> loadDepartments() async {
    departments = await AdminService.getDepartments();

    notifyListeners();
  }

  Future<void> createDepartment({
    required String name,
    String? description,
  }) async {
    await AdminService.createDepartment(name: name, description: description ?? '');

    await loadDepartments();
  }

  Future<void> deleteDepartment(int id) async {
    await AdminService.deleteDepartment(id);

    await loadDepartments();
  }

  // ============================================================
  // ROLES
  // ============================================================

  Future<void> loadRoles() async {
    roles = await AdminService.getRoles();

    notifyListeners();
  }

  Future<void> createRole(String name) async {
    await AdminService.createRole(name: name);

    await loadRoles();
  }

  // ============================================================
  // KIOSKS
  // ============================================================

  Future<void> loadKiosks() async {
    kiosks = await KioskService.getKiosks();

    notifyListeners();
  }

  Future<void> createKiosk({
    required String name,
    required String code,
    String? location,
    required String method,
    String? ipAddress,
    required bool active,
  }) async {
    kioskLoading = true;
    notifyListeners();

    try {
      await KioskService.createKiosk(
        name: name,
        code: code,
        location: location ?? '',
        method: method,
        ipAddress: ipAddress,
        active: active,
      );

      await loadKiosks();
    } finally {
      kioskLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleKiosk(int id) async {
    await KioskService.toggleKiosk(id);

    await loadKiosks();
  }

  Future<void> deleteKiosk(int id) async {
    await KioskService.deleteKiosk(id);

    await loadKiosks();
  }
}
