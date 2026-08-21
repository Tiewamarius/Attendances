import 'package:flutter/foundation.dart';

import 'package:attendance/models/model_leave.dart';
import 'package:attendance/services/leave_service.dart';

class LeaveController extends ChangeNotifier {
  // ============================================================
  // DATA
  // ============================================================

  List<LeaveModel> _leaves = [];

  bool _loading = false;

  String? _error;

  int? _processingId;

  // ============================================================
  // GETTERS
  // ============================================================

  List<LeaveModel> get leaves => _leaves;

  bool get loading => _loading;

  String? get error => _error;

  int? get processingId => _processingId;

  // ============================================================
  // STATISTIQUES
  // ============================================================

  int get pendingCount {
    return _leaves.where((leave) => leave.isPending).length;
  }

  int get approvedCount {
    return _leaves.where((leave) => leave.isApproved).length;
  }

  int get rejectedCount {
    return _leaves.where((leave) => leave.isRejected).length;
  }

  // ============================================================
  // CHARGER LES CONGES
  // ============================================================

  Future<void> loadLeaves() async {
    _loading = true;
    _error = null;

    notifyListeners();

    try {
      _leaves = await LeaveService.getLeaves();
    } catch (e) {
      _error = e.toString();
      debugPrint('LeaveController.loadLeaves: $e');
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // APPROUVER
  // ============================================================

  Future<bool> approveLeave(int id) async {
    _processingId = id;

    _error = null;

    notifyListeners();

    try {
      await LeaveService.hrApprove(id);

      await loadLeaves();

      return true;
    } catch (e) {
      _error = e.toString();

      debugPrint('LeaveController.approveLeave: $e');

      return false;
    } finally {
      _processingId = null;

      notifyListeners();
    }
  }

  // ============================================================
  // REFUSER
  // ============================================================

  Future<bool> rejectLeave(int id) async {
    _processingId = id;

    _error = null;

    notifyListeners();

    try {
      await LeaveService.hrReject(id);

      await loadLeaves();

      return true;
    } catch (e) {
      _error = e.toString();

      debugPrint('LeaveController.rejectLeave: $e');

      return false;
    } finally {
      _processingId = null;

      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadLeaves();
  }
}
