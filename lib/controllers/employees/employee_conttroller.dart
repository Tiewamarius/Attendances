import 'package:flutter/foundation.dart';

import 'package:attendance/models/employees/employee_model.dart';
import 'package:attendance/services/employees/employee_service.dart';

class EmployeeController extends ChangeNotifier {
  final EmployeeService _service = EmployeeService.instance;

  EmployeeModel? _employee;
  bool _loading = false;
  String? _error;

  EmployeeModel? get employee => _employee;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;

    notifyListeners();

    try {
      final employee = await _service.getProfile();

      _employee = employee;

      debugPrint('========================================');
      debugPrint('EMPLOYEE PROFILE CHARGÉ');
      debugPrint('ID         : ${employee.id}');
      debugPrint('Nom        : ${employee.firstName} ${employee.lastName}');
      debugPrint('Email      : ${employee.email}');
      debugPrint('Poste      : ${employee.position}');
      debugPrint('Image      : ${employee.profileImage}');
      debugPrint('Initiales   : ${employee.initials}');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      _employee = null;
      _error = e.toString();

      debugPrint('========================================');
      debugPrint('ERREUR EMPLOYEE PROFILE');
      debugPrint('$_error');
      debugPrint('$stackTrace');
      debugPrint('========================================');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _employee = null;
    _error = null;

    notifyListeners();
  }
}