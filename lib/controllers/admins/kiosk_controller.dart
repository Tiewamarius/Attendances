import 'package:attendance/models/admins/kiosk_model..dart';
import 'package:flutter/foundation.dart';
import 'package:attendance/services/admins/kiosk_service.dart';

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
      _error = _cleanError(e);

      debugPrint(
        'KioskController.loadKiosks: $e',
      );
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
    String? location,
    required String method,
    String? ipAddress,
    required bool active,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final kiosk = await KioskService.createKiosk(
        name: name,
        location: location,
        method: method,
        ipAddress: ipAddress,
        active: active,
      );

      _kiosks = [
        ..._kiosks, kiosk,
      ];

      return true;
    } catch (e) {
      _error = _cleanError(e);

      debugPrint(
        'KioskController.createKiosk: $e',
      );

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
    String? location,
    required String method,
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
        location: location,
        method: method,
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
      _error = _cleanError(e);

      debugPrint(
        'KioskController.updateKiosk: $e',
      );

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

      return true;
    } catch (e) {
      _error = _cleanError(e);

      debugPrint(
        'KioskController.toggleKiosk: $e',
      );

      return false;
    } finally {
      notifyListeners();
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

      return true;
    } catch (e) {
      _error = _cleanError(e);

      debugPrint(
        'KioskController.deleteKiosk: $e',
      );

      return false;
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}