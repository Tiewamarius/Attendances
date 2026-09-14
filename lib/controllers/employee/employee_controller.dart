import 'package:attendance/services/employee/employee_service.dart';
import 'package:flutter/foundation.dart';

import 'package:attendance/models/employee_model.dart';

class EmployeeController extends ChangeNotifier {
  EmployeeModel? _employee;

  bool _loading = false;
  String? _error;

  EmployeeModel? get employee => _employee;

  bool get loading => _loading;

  String? get error => _error;

  bool get hasEmployee => _employee != null;

  /// Charge d'abord le profil sauvegardé localement,
  /// puis tente de récupérer la version à jour depuis l'API.
  Future<void> loadProfile() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // ------------------------------------------------------------
      // 1. Charger immédiatement les données locales
      // ------------------------------------------------------------
      final savedEmployee =
          await EmployeeService.getSavedEmployee();

      if (savedEmployee != null) {
        _employee = savedEmployee;
        notifyListeners();
      }

      // ------------------------------------------------------------
      // 2. Rafraîchir depuis l'API
      // ------------------------------------------------------------
      final remoteEmployee =
          await EmployeeService.refreshProfile();

      if (remoteEmployee != null) {
        _employee = remoteEmployee;
        _error = null;
      } else if (_employee == null) {
        _error =
            'Impossible de récupérer votre profil employé.';
      }
    } catch (e) {
      debugPrint(
        'EmployeeController.loadProfile(): $e',
      );

      // Si on possède déjà les données locales,
      // on les conserve et on n'affiche pas une erreur bloquante.
      if (_employee == null) {
        _error =
            'Impossible de charger votre profil.';
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Rafraîchissement forcé depuis l'API.
  Future<bool> refresh() async {
    if (_loading) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final employee =
          await EmployeeService.refreshProfile();

      if (employee == null) {
        _error =
            'Impossible de mettre à jour votre profil.';
        return false;
      }

      _employee = employee;
      return true;
    } catch (e) {
      debugPrint(
        'EmployeeController.refresh(): $e',
      );

      _error =
          'Une erreur est survenue lors du rafraîchissement.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Efface uniquement les données employé locales.
  Future<void> clearEmployee() async {
    _employee = null;
    _error = null;

    await EmployeeService.clearSavedEmployee();

    notifyListeners();
  }

  /// Réinitialise uniquement l'erreur.
  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }
}