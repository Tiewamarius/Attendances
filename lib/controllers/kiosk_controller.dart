import 'package:flutter/foundation.dart';

import 'package:attendance/models/model_kiosk.dart';
import 'package:attendance/services/kiosk_service.dart';

class KioskController extends ChangeNotifier {
  // ============================================================
  // DATA
  // ============================================================

  List<KioskModel> _kiosks = [];

  List<KioskModel> get kiosks => _kiosks;

  // ============================================================
  // STATES
  // ============================================================

  bool _loading = false;

  bool get loading => _loading;

  bool _saving = false;

  bool get saving => _saving;

  String? _error;

  String? get error => _error;

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadKiosks() async {
    _loading = true;
    _error = null;

    notifyListeners();

    try {
      _kiosks = await KioskService.getKiosks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> createKiosk({
    required String name,
    required String code,
    String? location,
    required String mode,
    String? ipAddress,
    required bool active,
  }) async {
    _saving = true;
    _error = null;

    notifyListeners();

    try {
      final kiosk = await KioskService.createKiosk(
        name: name,
        code: code,
        location: location,
        mode: mode,
        ipAddress: ipAddress,
        active: active,
      );

      _kiosks = [
        ..._kiosks,
        kiosk,
      ];

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> updateKiosk({
    required int id,
    required String name,
    required String code,
    String? location,
    required String mode,
    String? ipAddress,
    required bool active,
  }) async {
    _saving = true;
    _error = null;

    notifyListeners();

    try {
      final updated = await KioskService.updateKiosk(
        id: id,
        name: name,
        code: code,
        location: location,
        mode: mode,
        ipAddress: ipAddress,
        active: active,
      );

      final index = _kiosks.indexWhere(
        (kiosk) => kiosk.id == id,
      );

      if (index != -1) {
        final list = [..._kiosks];

        list[index] = updated;

        _kiosks = list;
      }

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<bool> toggleKiosk(int id) async {
    _error = null;

    notifyListeners();

    try {
      final updated = await KioskService.toggleKiosk(id);

      final index = _kiosks.indexWhere(
        (kiosk) => kiosk.id == id,
      );

      if (index != -1) {
        final list = [..._kiosks];

        list[index] = updated;

        _kiosks = list;
      }

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deleteKiosk(int id) async {
    _error = null;

    notifyListeners();

    try {
      await KioskService.deleteKiosk(id);

      _kiosks = _kiosks
          .where((kiosk) => kiosk.id != id)
          .toList();

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;

    notifyListeners();
  }
}