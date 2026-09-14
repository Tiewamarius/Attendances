import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/kiosk_model.dart';

class KioskController extends ChangeNotifier {
  // ===========================================================================
  // ÉTAT
  // ===========================================================================

  List<KioskModel> _kiosks = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _errorMessage;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  List<KioskModel> get kiosks => List.unmodifiable(_kiosks);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isDeleting => _isDeleting;

  String? get errorMessage => _errorMessage;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final token = await AuthService.getToken();
      final organizationId =
          await AuthService.getOrganizationId();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.kiosks),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        _kiosks = _extractKiosks(body);
        return;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de récupérer les kiosques.',
      );
    } catch (e) {
      _errorMessage = _cleanException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<bool> create({
    required String name,
    required String code,
    String? location,
    required String mode,
    String? ipAddress,
  }) async {
    if (_isSaving) {
      return false;
    }

    final cleanName = name.trim();
    final cleanCode = code.trim();
    final cleanLocation = location?.trim() ?? '';
    final cleanIp = ipAddress?.trim() ?? '';

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (cleanName.isEmpty) {
      _errorMessage =
          'Le nom du kiosque est obligatoire.';

      notifyListeners();
      return false;
    }

    if (cleanCode.isEmpty) {
      _errorMessage =
          'Le code du kiosque est obligatoire.';

      notifyListeners();
      return false;
    }

    const allowedModes = {
      'KIOSK_QR',
      'KIOSK_PIN',
      'MOBILE',
      'MANUAL',
    };

    if (!allowedModes.contains(mode)) {
      _errorMessage =
          'Mode de kiosque invalide.';

      notifyListeners();
      return false;
    }

    // -------------------------------------------------------------------------
    // SAUVEGARDE
    // -------------------------------------------------------------------------

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final token = await AuthService.getToken();
      final organizationId =
          await AuthService.getOrganizationId();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final payload = <String, dynamic>{
        'name': cleanName,
        'code': cleanCode,
        'mode': mode,
        'active': true,
      };

      if (cleanLocation.isNotEmpty) {
        payload['location'] = cleanLocation;
      }

      if (cleanIp.isNotEmpty) {
        payload['ip_address'] = cleanIp;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.kiosks),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
        body: jsonEncode(payload),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        await load();
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de créer le kiosque.',
      );

      return false;
    } catch (e) {
      _errorMessage = _cleanException(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  Future<bool> update(
    int kioskId, {
    required String name,
    required String code,
    String? location,
    required String mode,
    String? ipAddress,
    bool? active,
  }) async {
    if (_isSaving) {
      return false;
    }

    final cleanName = name.trim();
    final cleanCode = code.trim();
    final cleanLocation = location?.trim() ?? '';
    final cleanIp = ipAddress?.trim() ?? '';

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (cleanName.isEmpty) {
      _errorMessage =
          'Le nom du kiosque est obligatoire.';

      notifyListeners();
      return false;
    }

    if (cleanCode.isEmpty) {
      _errorMessage =
          'Le code du kiosque est obligatoire.';

      notifyListeners();
      return false;
    }

    const allowedModes = {
      'KIOSK_QR',
      'KIOSK_PIN',
      'MOBILE',
      'MANUAL',
    };

    if (!allowedModes.contains(mode)) {
      _errorMessage =
          'Mode de kiosque invalide.';

      notifyListeners();
      return false;
    }

    // -------------------------------------------------------------------------
    // SAUVEGARDE
    // -------------------------------------------------------------------------

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final token = await AuthService.getToken();
      final organizationId =
          await AuthService.getOrganizationId();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final payload = <String, dynamic>{
        'name': cleanName,
        'code': cleanCode,
        'mode': mode,
        'location': cleanLocation.isEmpty
            ? null
            : cleanLocation,
        'ip_address': cleanIp.isEmpty
            ? null
            : cleanIp,
      };

      if (active != null) {
        payload['active'] = active;
      }

      final response = await http.put(
        Uri.parse(
          ApiConfig.kiosk(kioskId),
        ),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
        body: jsonEncode(payload),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        await load();
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de modifier le kiosque.',
      );

      return false;
    } catch (e) {
      _errorMessage = _cleanException(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // TOGGLE
  // ===========================================================================

  Future<bool> toggle(KioskModel kiosk) async {
    if (_isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final token = await AuthService.getToken();
      final organizationId =
          await AuthService.getOrganizationId();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final response = await http.patch(
        Uri.parse(
          ApiConfig.kioskToggle(kiosk.id),
        ),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        await load();
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de modifier l’état du kiosque.',
      );

      return false;
    } catch (e) {
      _errorMessage = _cleanException(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<bool> delete(int kioskId) async {
    if (_isDeleting) {
      return false;
    }

    _isDeleting = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final token = await AuthService.getToken();
      final organizationId =
          await AuthService.getOrganizationId();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final response = await http.delete(
        Uri.parse(
          ApiConfig.kiosk(kioskId),
        ),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        _kiosks.removeWhere(
          (kiosk) => kiosk.id == kioskId,
        );

        notifyListeners();

        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de supprimer le kiosque.',
      );

      return false;
    } catch (e) {
      _errorMessage = _cleanException(e);
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // HEADERS
  // ===========================================================================

  Map<String, String> _headers({
    required String token,
    required int organizationId,
  }) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Organization-Id':
          organizationId.toString(),
    };
  }

  // ===========================================================================
  // RESPONSE
  // ===========================================================================

  dynamic _decodeResponse(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{
        'message': response.body,
      };
    }
  }

  // ===========================================================================
  // EXTRACTION KIOSKS
  // ===========================================================================

  List<KioskModel> _extractKiosks(
    dynamic body,
  ) {
    dynamic data;

    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        data = data['data'] ??
            data['kiosks'] ??
            data['items'];
      }

      data ??= body['kiosks'];
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => KioskModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  String _extractError(
    dynamic body, {
    required String fallback,
  }) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        return message;
      }

      final errors = body['errors'];

      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List &&
              value.isNotEmpty) {
            return value.first.toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }
    }

    return fallback;
  }

  // ===========================================================================
  // EXCEPTION
  // ===========================================================================

  String _cleanException(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}