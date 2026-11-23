import 'dart:async';
import 'dart:convert';

import 'package:attendance/core/offline/connectivity_service.dart';
import 'package:attendance/services/kiosk/kiosk_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// File d'attente des pointages faits hors ligne sur le kiosk.
///
/// - Cas normal : l'employé est reconnu par l'annuaire de la tablette
///   (KioskDirectory). On ne garde que son identifiant + l'heure du scan.
/// - Sans annuaire (premier démarrage hors ligne) : on garde le PIN/QR saisi,
///   que le serveur vérifie à la synchronisation.
/// - À la reconnexion, le serveur pointe à l'heure réelle du scan.
/// - Chaque pointage a un client_id : jamais traité deux fois.
///
/// Limite connue : dans le cas « sans annuaire », un PIN en attente est
/// stocké en clair dans les préférences jusqu'à la synchronisation.
class KioskOfflineQueue {
  KioskOfflineQueue._();

  static final KioskOfflineQueue instance = KioskOfflineQueue._();

  static const String _key = 'kiosk_offline_queue';

  /// Anti double-scan : même PIN/QR re-présenté trop vite hors ligne.
  static const Duration _duplicateWindow = Duration(seconds: 60);

  /// Nombre de pointages en attente de synchronisation.
  final ValueNotifier<int> pending = ValueNotifier<int>(0);

  /// Pointages refusés par le serveur à la dernière synchronisation
  /// (message affiché une fois par le kiosk).
  final ValueNotifier<List<String>> rejected =
      ValueNotifier<List<String>>(const []);

  final Uuid _uuid = const Uuid();

  KioskService? _service;
  bool _syncing = false;
  bool _initialized = false;

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init(KioskService service) async {
    _service = service;

    if (_initialized) return;
    _initialized = true;

    pending.value = (await _load()).length;

    // Retour de connexion => synchronisation immédiate.
    ConnectivityService.instance.online.addListener(() {
      if (ConnectivityService.instance.online.value) {
        sync();
      }
    });

    // Filet de sécurité : réessai périodique s'il reste des éléments.
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (pending.value > 0 && ConnectivityService.instance.online.value) {
        sync();
      }
    });

    if (pending.value > 0) {
      unawaited(sync());
    }
  }

  // ============================================================
  // STOCKAGE
  // ============================================================

  Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
    pending.value = items.length;
  }

  // ============================================================
  // AJOUT
  // ============================================================

  /// [method] : 'PIN' ou 'QR'.
  ///
  /// Deux formes :
  /// - [employeeId] : employé déjà reconnu par l'annuaire de la tablette
  ///   (aucun PIN ni QR n'est conservé) ;
  /// - [secret] : le PIN ou le token QR tel que saisi/scanné, quand la
  ///   tablette n'a pas encore d'annuaire (le serveur vérifiera à la synchro).
  ///
  /// Retourne false si c'est un doublon immédiat (ignoré).
  Future<bool> enqueue({
    required String method,
    String? secret,
    int? employeeId,
  }) async {
    assert(secret != null || employeeId != null);

    final items = await _load();
    final now = DateTime.now().toUtc();

    final duplicate = items.any((item) {
      if (item['method'] != method) return false;

      final same = employeeId != null
          ? item['employee_id'] == employeeId
          : item['secret'] == secret;

      if (!same) return false;

      final at = DateTime.tryParse('${item['scanned_at']}');

      return at != null && now.difference(at) < _duplicateWindow;
    });

    if (duplicate) return false;

    items.add({
      'client_id': _uuid.v4(),
      'method': method,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeId == null) 'secret': secret,
      'scanned_at': now.toIso8601String(),
    });

    await _save(items);

    return true;
  }

  // ============================================================
  // SYNCHRONISATION
  // ============================================================

  Future<void> sync() async {
    final service = _service;

    if (service == null || _syncing) return;

    _syncing = true;

    try {
      final items = await _load();

      if (items.isEmpty) return;

      // Lots de 100 max (limite du serveur).
      final batch = items.take(100).toList();

      final payload = batch
          .map((item) => {
                'client_id': item['client_id'],
                'method': item['method'],
                if (item['employee_id'] != null)
                  'employee_id': item['employee_id'],
                if (item['employee_id'] == null && item['method'] == 'PIN')
                  'pin': item['secret'],
                if (item['employee_id'] == null && item['method'] == 'QR')
                  'token': item['secret'],
                'scanned_at': item['scanned_at'],
              })
          .toList();

      final results = await service.syncPunches(payload);

      // Un résultat (synchronisé OU refusé) = traité : on le retire.
      final done = results.map((r) => '${r['client_id']}').toSet();

      final remaining = items
          .where((item) => !done.contains('${item['client_id']}'))
          .toList();

      await _save(remaining);

      final refused = results
          .where((r) => r['status'] == 'rejected')
          .map((r) => '${r['employee'] ?? 'Pointage'} : ${r['message']}')
          .toList();

      if (refused.isNotEmpty) {
        rejected.value = refused;
      }

      debugPrint(
        '[SYNC] ${results.length} traité(s), ${remaining.length} restant(s).',
      );

      // S'il reste des éléments au-delà du lot, on enchaîne.
      if (remaining.isNotEmpty && results.isNotEmpty) {
        _syncing = false;
        await sync();
      }
    } catch (e) {
      // Réseau coupé ou serveur en erreur : tout reste en file.
      debugPrint('[SYNC] Échec, réessai plus tard : $e');

      if (isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
      }
    } finally {
      _syncing = false;
    }
  }
}
