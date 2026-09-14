import 'package:attendance/controllers/admin/settings/department_controller.dart';
import 'package:attendance/controllers/admin/settings/profile_controller.dart';
import 'package:attendance/controllers/admin/settings/kiosk_controller.dart';
import 'package:flutter/foundation.dart';

/// Sections disponibles dans les paramètres administrateur.
enum SettingsSection {
  profile,
  departments,
  kiosks,
}

/// Controller principal de la page Paramètres.
///
/// Il orchestre :
/// - ProfileController
/// - DepartmentController
/// - KioskController
///
/// La logique API reste dans les controllers spécialisés.
class SettingsController extends ChangeNotifier {
  SettingsController({
    ProfileController? profileController,
    DepartmentController? departmentController,
    KioskController? kioskController,
  })  : profileController =
            profileController ?? ProfileController(),
        departmentController =
            departmentController ?? DepartmentController(),
        kioskController =
            kioskController ?? KioskController();

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final ProfileController profileController;
  final DepartmentController departmentController;
  final KioskController kioskController;

  // ===========================================================================
  // ÉTAT
  // ===========================================================================

  SettingsSection _section = SettingsSection.profile;

  bool _initialized = false;
  bool _isInitializing = false;

  bool _showDepartmentForm = false;
  bool _showKioskForm = false;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  SettingsSection get section => _section;

  bool get initialized => _initialized;

  bool get isInitializing => _isInitializing;

  bool get showDepartmentForm => _showDepartmentForm;

  bool get showKioskForm => _showKioskForm;

  // ===========================================================================
  // INITIALISATION
  // ===========================================================================

  Future<void> initialize() async {
    if (_initialized || _isInitializing) {
      return;
    }

    _isInitializing = true;
    notifyListeners();

    try {
      await Future.wait([
        profileController.loadprofile(),
        departmentController.loaddepartments(),
        kioskController.load(),
      ]);

      _initialized = true;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // SECTION
  // ===========================================================================

  void selectSection(SettingsSection section) {
    if (_section == section) {
      return;
    }

    _section = section;

    // Fermer les formulaires lorsque l'utilisateur
    // change de section.
    _showDepartmentForm = false;
    _showKioskForm = false;

    notifyListeners();

    _loadSectionIfNecessary(section);
  }

  Future<void> _loadSectionIfNecessary(
    SettingsSection section,
  ) async {
    switch (section) {
      case SettingsSection.profile:
        if (profileController.user == null &&
            !profileController.isLoading) {
          await profileController.loadprofile();
        }
        break;

      case SettingsSection.departments:
        if (!departmentController.isLoading) {
          await departmentController.loaddepartments();
        }
        break;

      case SettingsSection.kiosks:
        if (!kioskController.isLoading) {
          await kioskController.load();
        }
        break;
    }
  }

  // ===========================================================================
  // FORMULAIRE DÉPARTEMENT
  // ===========================================================================

  void toggleDepartmentForm() {
    _showDepartmentForm = !_showDepartmentForm;

    if (_showDepartmentForm) {
      _showKioskForm = false;
    }

    notifyListeners();
  }

  void openDepartmentForm() {
    if (_showDepartmentForm) {
      return;
    }

    _showDepartmentForm = true;
    _showKioskForm = false;

    notifyListeners();
  }

  void closeDepartmentForm() {
    if (!_showDepartmentForm) {
      return;
    }

    _showDepartmentForm = false;

    notifyListeners();
  }

  // ===========================================================================
  // FORMULAIRE KIOSQUE
  // ===========================================================================

  void toggleKioskForm() {
    _showKioskForm = !_showKioskForm;

    if (_showKioskForm) {
      _showDepartmentForm = false;
    }

    notifyListeners();
  }

  void openKioskForm() {
    if (_showKioskForm) {
      return;
    }

    _showKioskForm = true;
    _showDepartmentForm = false;

    notifyListeners();
  }

  void closeKioskForm() {
    if (!_showKioskForm) {
      return;
    }

    _showKioskForm = false;

    notifyListeners();
  }

  // ===========================================================================
  // RAFRAÎCHISSEMENT
  // ===========================================================================

  Future<void> refreshCurrentSection() async {
    switch (_section) {
      case SettingsSection.profile:
        await profileController.loadprofile();
        break;

      case SettingsSection.departments:
        await departmentController.loaddepartments();
        break;

      case SettingsSection.kiosks:
        await kioskController.load();
        break;
    }

    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      profileController.loadprofile(),
      departmentController.loaddepartments(),
      kioskController.load(),
    ]);

    notifyListeners();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    profileController.dispose();
    departmentController.dispose();
    kioskController.dispose();

    super.dispose();
  }
}