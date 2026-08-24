import 'package:flutter/foundation.dart';

import 'package:attendance/models/admins/department_model.dart';
import 'package:attendance/models/admins/kiosk_model..dart';
import 'package:attendance/models/admins/model_roles.dart';
import 'package:attendance/models/user_model.dart';

import 'package:attendance/services/user_service.dart';
import 'package:attendance/services/admins/kiosk_service.dart';

class SettingsController extends ChangeNotifier {
  // ============================================================
  // DATA
  // ============================================================

  UserModel? profile;

  List<DepartmentModel> departments = [];

  List<RoleModel> roles = [];

  List<KioskModel> kiosks = [];

  List<UserModel> users = [];

  // ============================================================
  // STATES
  // ============================================================

  bool loading = false;

  bool profileLoading = false;

  bool departmentLoading = false;

  bool roleLoading = false;

  bool userLoading = false;

  bool kioskLoading = false;

  // ============================================================
  // ERROR
  // ============================================================

  String? errorMessage;

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  Future<void> loadInitialData() async {
    loading = true;
    errorMessage = null;

    notifyListeners();

    try {
      await Future.wait([
        loadProfile(),
        loadDepartments(),
        loadRoles(),
        loadUsers(),
        loadKiosks(),
      ]);
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des paramètres.';
      debugPrint(
        'SettingsController.loadInitialData: $e',
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PROFILE
  // GET /auth/me
  // ============================================================

  Future<void> loadProfile() async {
    profileLoading = true;
    notifyListeners();

    try {
      profile = await UserService.getProfile();
    } catch (e) {
      debugPrint(
        'SettingsController.loadProfile: $e',
      );
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  /*
   * IMPORTANT :
   *
   * Le backend actuel ne possède pas de route :
   *
   * PUT /auth/me
   *
   * Donc cette méthode ne doit pas prétendre modifier le profil.
   *
   * La modification pourra être branchée plus tard sur :
   * PUT /users/{user}
   *
   * si l'utilisateur connecté est identifié.
   */

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  Future<void> loadDepartments() async {
    try {
      departments = await UserService.getDepartments();
    } catch (e) {
      debugPrint(
        'SettingsController.loadDepartments: $e',
      );
    }

    notifyListeners();
  }

  // ============================================================
  // DEPARTMENT - DETAIL
  // GET /departments/{id}
  // ============================================================

  Future<DepartmentModel?> getDepartment(int id) async {
    try {
      return await UserService.getDepartment(id);
    } catch (e) {
      debugPrint(
        'SettingsController.getDepartment: $e',
      );
      return null;
    }
  }

  // ============================================================
  // DEPARTMENT - CREATE
  // POST /departments
  // ============================================================

  Future<bool> createDepartment({
    required String name,
    String? description,
  }) async {
    departmentLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final department =
          await UserService.createDepartment(
        name: name,
        description: description,
      );

      if (department == null) {
        return false;
      }

      await loadDepartments();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de créer le département.';

      debugPrint(
        'SettingsController.createDepartment: $e',
      );

      return false;
    } finally {
      departmentLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DEPARTMENT - UPDATE
  // PUT /departments/{id}
  // ============================================================

  Future<bool> updateDepartment({
    required int id,
    required String name,
    String? description,
  }) async {
    departmentLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final department =
          await UserService.updateDepartment(
        id: id,
        name: name,
        description: description,
      );

      if (department == null) {
        return false;
      }

      await loadDepartments();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de modifier le département.';

      debugPrint(
        'SettingsController.updateDepartment: $e',
      );

      return false;
    } finally {
      departmentLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DEPARTMENT - DELETE
  // DELETE /departments/{id}
  // ============================================================

  Future<bool> deleteDepartment(int id) async {
    departmentLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final success =
          await UserService.deleteDepartment(id);

      if (!success) {
        return false;
      }

      await loadDepartments();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de supprimer le département.';

      debugPrint(
        'SettingsController.deleteDepartment: $e',
      );

      return false;
    } finally {
      departmentLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ROLES
  // GET /users/roles
  // ============================================================

  Future<void> loadRoles() async {
    roleLoading = true;
    notifyListeners();

    try {
      roles = await UserService.getRoles();
    } catch (e) {
      roles = [];

      debugPrint(
        'SettingsController.loadRoles: $e',
      );
    } finally {
      roleLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  /*
   * Il n'existe actuellement PAS de route CRUD :
   *
   * POST   /roles
   * PUT    /roles/{id}
   * DELETE /roles/{id}
   *
   * Donc on ne crée/modifie/supprime pas de rôle ici.
   *
   * /setup/roles est réservé à l'installation initiale.
   */

  Future<void> refreshRoles() async {
    await loadRoles();
  }

  // ============================================================
  // USERS
  // ============================================================

  Future<void> loadUsers() async {
    userLoading = true;
    notifyListeners();

    try {
      users = await UserService.getUsers();
    } catch (e) {
      users = [];

      debugPrint(
        'SettingsController.loadUsers: $e',
      );
    } finally {
      userLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // USER - DETAIL
  // GET /users/{id}
  // ============================================================

  Future<UserModel?> getUser(int id) async {
    try {
      return await UserService.getUser(id);
    } catch (e) {
      debugPrint(
        'SettingsController.getUser: $e',
      );

      return null;
    }
  }

  // ============================================================
  // USER - CREATE
  // POST /users
  // ============================================================

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    String? role,
  }) async {
    userLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final success =
          await UserService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (!success) {
        return false;
      }

      await loadUsers();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de créer l’utilisateur.';

      debugPrint(
        'SettingsController.createUser: $e',
      );

      return false;
    } finally {
      userLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // USER - UPDATE
  // PUT /users/{id}
  // ============================================================

  Future<bool> updateUser({
    required int id,
    required String name,
    required String email,
    String? role,
  }) async {
    userLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final success =
          await UserService.updateUser(
        id: id,
        name: name,
        email: email,
        role: role,
      );

      if (!success) {
        return false;
      }

      await loadUsers();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de modifier l’utilisateur.';

      debugPrint(
        'SettingsController.updateUser: $e',
      );

      return false;
    } finally {
      userLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // USER - DELETE
  // DELETE /users/{id}
  // ============================================================

  Future<bool> deleteUser(int id) async {
    userLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final success =
          await UserService.deleteUser(id);

      if (!success) {
        return false;
      }

      await loadUsers();

      return true;
    } catch (e) {
      errorMessage =
          'Impossible de supprimer l’utilisateur.';

      debugPrint(
        'SettingsController.deleteUser: $e',
      );

      return false;
    } finally {
      userLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
// KIOSKS
// ============================================================

Future<void> loadKiosks() async {
  try {
    kiosks = await KioskService.getKiosks();
  } catch (e) {
    kiosks = [];

    debugPrint(
      'SettingsController.loadKiosks: $e',
    );
  }

  notifyListeners();
}

// ============================================================
// KIOSK - CREATE
// POST /kiosks
// ============================================================

Future<bool> createKiosk({
  required String code,
  required String name,
  String? location,
  required String method,
  String? ipAddress,
  required bool active,
}) async {
  kioskLoading = true;
  errorMessage = null;

  notifyListeners();

  try {
    await KioskService.createKiosk(

      name: name,
      location: location,
      method: method,
      ipAddress: ipAddress,
      active: active,
    );

    await loadKiosks();

    return true;
  } catch (e) {
    errorMessage =
        'Impossible de créer le kiosk.';

    debugPrint(
      'SettingsController.createKiosk: $e',
    );

    return false;
  } finally {
    kioskLoading = false;
    notifyListeners();
  }
}

// ============================================================
// KIOSK - TOGGLE
// PATCH /kiosks/{id}/toggle
// ============================================================

Future<bool> toggleKiosk(int id) async {
  kioskLoading = true;
  errorMessage = null;

  notifyListeners();

  try {
    await KioskService.toggleKiosk(id);

    await loadKiosks();

    return true;
  } catch (e) {
    errorMessage =
        'Impossible de modifier l’état du kiosk.';

    debugPrint(
      'SettingsController.toggleKiosk: $e',
    );

    return false;
  } finally {
    kioskLoading = false;
    notifyListeners();
  }
}

// ============================================================
// KIOSK - DELETE
// DELETE /kiosks/{id}
// ============================================================

Future<bool> deleteKiosk(int id) async {
  kioskLoading = true;
  errorMessage = null;

  notifyListeners();

  try {
    await KioskService.deleteKiosk(id);

    await loadKiosks();

    return true;
  } catch (e) {
    errorMessage =
        'Impossible de supprimer le kiosk.';

    debugPrint(
      'SettingsController.deleteKiosk: $e',
    );

    return false;
  } finally {
    kioskLoading = false;
    notifyListeners();
  }
}

// ============================================================
// RESET ERROR
// ============================================================

void clearError() {
  errorMessage = null;
  notifyListeners();
}
}