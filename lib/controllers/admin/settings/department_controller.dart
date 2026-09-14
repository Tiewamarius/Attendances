import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/department_model.dart';

class DepartmentController extends ChangeNotifier {
  // ===========================================================================
  // ÉTAT
  // ===========================================================================

  List<DepartmentModel> _departments = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _errorMessage;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  List<DepartmentModel> get departments =>
      List.unmodifiable(_departments);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isDeleting => _isDeleting;

  String? get errorMessage => _errorMessage;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> loaddepartments() async {
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
        throw Exception('Session utilisateur introuvable.');
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        _departments = _extractDepartments(body);
        return;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de récupérer les départements.',
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
    String? description,
  }) async {
    if (_isSaving) {
      return false;
    }

    final cleanName = name.trim();
    final cleanDescription =
        description?.trim() ?? '';

    if (cleanName.isEmpty) {
      _errorMessage =
          'Le nom du département est obligatoire.';
      notifyListeners();
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
        throw Exception('Session utilisateur introuvable.');
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final payload = <String, dynamic>{
        'name': cleanName,
      };

      if (cleanDescription.isNotEmpty) {
        payload['description'] = cleanDescription;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.departments),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
        body: jsonEncode(payload),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        await loaddepartments();
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de créer le département.',
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

  Future<bool> delete(int departmentId) async {
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
        throw Exception('Session utilisateur introuvable.');
      }

      if (organizationId == null) {
        throw Exception(
          'Aucune organisation active n’a été sélectionnée.',
        );
      }

      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.departments}/$departmentId',
        ),
        headers: _headers(
          token: token,
          organizationId: organizationId,
        ),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        _departments.removeWhere(
          (department) => department.id == departmentId,
        );

        notifyListeners();
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de supprimer le département.',
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
      'X-Organization-Id': organizationId.toString(),
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

  List<DepartmentModel> _extractDepartments(
    dynamic body,
  ) {
    dynamic data;

    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        data = data['data'] ??
            data['departments'] ??
            data['items'];
      }

      data ??= body['departments'];
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => DepartmentModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

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

  String _cleanException(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}