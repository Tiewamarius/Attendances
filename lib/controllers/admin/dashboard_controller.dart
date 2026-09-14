import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/dashboard_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DashboardController extends ChangeNotifier {
  DashboardModel? _dashboard;

  bool _loading = false;
  String? _error;

  DashboardModel? get dashboard => _dashboard;

  bool get loading => _loading;

  String? get error => _error;

  bool get hasData => _dashboard != null;

  Future<void> load() async {
    if (_loading) {
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final organizationId = await AuthService.getOrganizationId();

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active.',
        );
      }

      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: await AuthService.headers(
          includeOrganization: true,
        ),
      );

      if (response.statusCode == 401) {
        await AuthService.clearSession();

        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      final body = _decode(response);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _messageFromResponse(body) ??
              'Impossible de charger le dashboard.',
        );
      }

      if (body == null || body['status'] != true) {
        throw Exception(
          _messageFromResponse(body) ??
              'Impossible de charger le dashboard.',
        );
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        throw Exception(
          'Réponse dashboard invalide.',
        );
      }

      _dashboard = DashboardModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } catch (e) {
      _error = _cleanError(e);

      if (kDebugMode) {
        debugPrint(
          'DashboardController.load: $_error',
        );
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void clear() {
    _dashboard = null;
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic>? _decode(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  String? _messageFromResponse(
    Map<String, dynamic>? body,
  ) {
    final message = body?['message'];

    if (message == null) {
      return null;
    }

    final value = message.toString().trim();

    return value.isEmpty ? null : value;
  }

  String _cleanError(Object error) {
    final value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring(11);
    }

    return value;
  }
}