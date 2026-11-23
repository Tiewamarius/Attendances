import 'dart:async';
import 'dart:convert';

import 'package:attendance/core/offline/connectivity_service.dart';
import 'package:attendance/services/kiosk/kiosk_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Résultat de la reconnaissance d'un employé sur la tablette.
class DirectoryMatch {
  const DirectoryMatch.found(this.employee) : ambiguous = false;
  const DirectoryMatch.ambiguous()
      : employee = null,
        ambiguous = true;

  /// Employé reconnu (null si inconnu ou ambigu).
  final Map<String, dynamic>? employee;

  /// Plusieurs employés partagent ce PIN : on ne devine jamais.
  final bool ambiguous;

  int? get employeeId => int.tryParse('${employee?['id']}');

  String get fullName {
    final e = employee;
    if (e == null) return '';
    return '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
  }
}

/// Annuaire local du kiosk : permet de reconnaître un QR ou un PIN SANS réseau.
///
/// Ce que la tablette garde (téléchargé depuis GET /kiosk/sync/data) :
/// - QR : seulement l'empreinte SHA-256 des jetons valides, jamais le jeton ;
/// - PIN : l'empreinte HMAC-SHA256 de chaque PIN + le secret de l'organisation
///   (jamais le PIN, jamais le hash bcrypt) ;
/// - l'état du jour (arrivée/départ déjà faits) pour décider arrivée ou départ.
///
/// Le tout est chiffré par le stockage sécurisé du système (Keystore Android).
/// Limite connue : un PIN à 6 chiffres reste devinable par force brute par
/// quelqu'un qui extrairait le secret ET l'annuaire d'une tablette rootée ;
/// d'où le verrouillage après des échecs répétés et le chiffrement.
class KioskDirectory {
  KioskDirectory._();

  static final KioskDirectory instance = KioskDirectory._();

  static const String _storageKey = 'kiosk_directory_v1';
  static const String _overlayKey = 'kiosk_directory_overlay_v1';

  /// Échecs de PIN tolérés avant verrouillage, et durée du verrouillage.
  static const int _maxFailures = 5;
  static const Duration _failureWindow = Duration(minutes: 5);
  static const Duration _lockDuration = Duration(minutes: 2);

  /// Rafraîchissement périodique quand le serveur est joignable.
  static const Duration _refreshEvery = Duration(minutes: 15);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// true quand un annuaire est disponible sur la tablette.
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  KioskService? _service;
  bool _initialized = false;
  bool _refreshing = false;

  Map<String, dynamic>? _data;

  /// Pointages faits hors ligne depuis le dernier téléchargement :
  /// { '<employeeId>': { 'date': 'YYYY-MM-DD', 'in': bool, 'out': bool } }
  Map<String, dynamic> _overlay = {};

  final List<DateTime> _failures = [];
  DateTime? _lockedUntil;

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init(KioskService service) async {
    _service = service;

    if (_initialized) return;
    _initialized = true;

    await _loadFromStorage();

    ConnectivityService.instance.online.addListener(() {
      if (ConnectivityService.instance.online.value) {
        unawaited(refresh());
      }
    });

    Timer.periodic(_refreshEvery, (_) {
      if (ConnectivityService.instance.online.value) {
        unawaited(refresh());
      }
    });

    if (ConnectivityService.instance.online.value) {
      unawaited(refresh());
    }
  }

  // ============================================================
  // TÉLÉCHARGEMENT
  // ============================================================

  /// Télécharge l'annuaire. Sans effet si le serveur est injoignable :
  /// l'ancien annuaire reste utilisable.
  Future<bool> refresh() async {
    final service = _service;

    if (service == null || _refreshing) return false;

    _refreshing = true;

    try {
      final data = await service.getSyncData();

      _data = data;
      // Le serveur connaît désormais tous nos pointages synchronisés.
      // Ceux encore en file restent représentés par l'overlay.
      _dropStaleOverlay();

      await _storage.write(key: _storageKey, value: jsonEncode(data));
      await _saveOverlay();

      ready.value = true;

      debugPrint(
        '[ANNUAIRE] ${(data['employees'] as List?)?.length ?? 0} employé(s), '
        '${(data['qr_tokens'] as List?)?.length ?? 0} QR.',
      );

      return true;
    } catch (e) {
      debugPrint('[ANNUAIRE] Téléchargement impossible : $e');

      if (isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
      }

      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// À appeler quand le kiosk se déconnecte : on n'efface rien sur la
  /// tablette d'un autre employeur.
  Future<void> clear() async {
    _data = null;
    _overlay = {};
    ready.value = false;

    await _storage.delete(key: _storageKey);
    await _storage.delete(key: _overlayKey);
  }

  // ============================================================
  // RECONNAISSANCE
  // ============================================================

  /// null = pas d'annuaire (premier démarrage hors ligne).
  DirectoryMatch? findByPin(String pin) {
    final data = _data;
    final pepper = data?['pepper'];

    if (data == null || pepper is! String || pepper.isEmpty) return null;

    final lookup = Hmac(sha256, utf8.encode(pepper))
        .convert(utf8.encode(pin.trim()))
        .toString();

    final matches = _employees()
        .where((e) => e['pin_lookup'] == lookup)
        .toList();

    if (matches.length > 1) return const DirectoryMatch.ambiguous();

    return matches.isEmpty
        ? const DirectoryMatch.found(null)
        : DirectoryMatch.found(matches.first);
  }

  /// null = pas d'annuaire (premier démarrage hors ligne).
  DirectoryMatch? findByQr(String token) {
    final data = _data;

    if (data == null) return null;

    final hash = sha256.convert(utf8.encode(token.trim())).toString();
    final now = DateTime.now().toUtc();

    final tokens = (data['qr_tokens'] as List? ?? [])
        .whereType<Map>()
        .where((t) => t['hash'] == hash);

    for (final t in tokens) {
      final expires = DateTime.tryParse('${t['expires_at']}');

      if (expires != null && expires.isBefore(now)) continue;

      final employee = _employees().firstWhere(
        (e) => '${e['id']}' == '${t['employee_id']}',
        orElse: () => const {},
      );

      if (employee.isNotEmpty) return DirectoryMatch.found(employee);
    }

    return const DirectoryMatch.found(null);
  }

  List<Map<String, dynamic>> _employees() {
    return (_data?['employees'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ============================================================
  // ARRIVÉE OU DÉPART ?
  // ============================================================

  /// Prochain pointage de cet employé : 'check_in' ou 'check_out',
  /// ou null si sa journée est déjà complète (même règle que le serveur :
  /// 1er passage arrivée, 2e départ, 3e refusé). N'enregistre rien.
  String? peekPunch(int employeeId) {
    final state = _stateFor(employeeId);

    if (!state.checkedIn) return 'check_in';
    if (!state.checkedOut) return 'check_out';

    return null;
  }

  /// Mémorise un pointage fait sur cette tablette (après sa mise en file).
  Future<void> recordPunch(int employeeId) async {
    final state = _stateFor(employeeId);

    if (!state.checkedIn) {
      state.checkedIn = true;
    } else {
      state.checkedOut = true;
    }

    _overlay['$employeeId'] = {
      'date': _today(),
      'in': state.checkedIn,
      'out': state.checkedOut,
    };

    await _saveOverlay();
  }

  _DayState _stateFor(int employeeId) {
    final state = _DayState();

    // État connu du serveur au moment du téléchargement (valable le jour même).
    final generated = DateTime.tryParse('${_data?['generated_at']}')?.toLocal();

    if (generated != null && _sameDay(generated, DateTime.now())) {
      for (final row in (_data?['today'] as List? ?? []).whereType<Map>()) {
        if ('${row['employee_id']}' == '$employeeId') {
          state.checkedIn = row['checked_in'] == true;
          state.checkedOut = row['checked_out'] == true;
        }
      }
    }

    // Pointages faits sur cette tablette depuis.
    final local = _overlay['$employeeId'];

    if (local is Map && local['date'] == _today()) {
      state.checkedIn = state.checkedIn || local['in'] == true;
      state.checkedOut = state.checkedOut || local['out'] == true;
    }

    return state;
  }

  // ============================================================
  // VERROUILLAGE APRÈS ÉCHECS DE PIN
  // ============================================================

  /// Durée restante de verrouillage, ou null.
  Duration? lockedFor() {
    final until = _lockedUntil;

    if (until == null) return null;

    final left = until.difference(DateTime.now());

    if (left.isNegative) {
      _lockedUntil = null;
      return null;
    }

    return left;
  }

  void registerPinFailure() {
    final now = DateTime.now();

    _failures
      ..removeWhere((t) => now.difference(t) > _failureWindow)
      ..add(now);

    if (_failures.length >= _maxFailures) {
      _lockedUntil = now.add(_lockDuration);
      _failures.clear();
    }
  }

  void registerPinSuccess() => _failures.clear();

  // ============================================================
  // STOCKAGE
  // ============================================================

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _storageKey);

      if (raw != null && raw.isNotEmpty) {
        _data = Map<String, dynamic>.from(jsonDecode(raw));
        ready.value = true;
      }

      final overlay = await _storage.read(key: _overlayKey);

      if (overlay != null && overlay.isNotEmpty) {
        _overlay = Map<String, dynamic>.from(jsonDecode(overlay));
        _dropStaleOverlay();
      }
    } catch (e) {
      debugPrint('[ANNUAIRE] Lecture impossible : $e');
      _data = null;
      ready.value = false;
    }
  }

  Future<void> _saveOverlay() =>
      _storage.write(key: _overlayKey, value: jsonEncode(_overlay));

  void _dropStaleOverlay() {
    final today = _today();

    _overlay.removeWhere(
      (_, value) => value is! Map || value['date'] != today,
    );
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayState {
  bool checkedIn = false;
  bool checkedOut = false;
}
