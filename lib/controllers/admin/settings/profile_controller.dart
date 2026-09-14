import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/user_model.dart';

class ProfileController extends ChangeNotifier {
  // ===========================================================================
  // ÉTAT
  // ===========================================================================

  UserModel? _user;

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  // ===========================================================================
  // LOAD PROFILE
  // ===========================================================================

  Future<void> loadprofile() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session utilisateur introuvable.');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.currentUserAdmin),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        final userData = _extractUser(body);

        if (userData == null) {
          throw Exception(
            'Les informations du profil sont introuvables.',
          );
        }

        _user = UserModel.fromJson(userData);
        return;
      }

      if (response.statusCode == 401) {
        _errorMessage =
            'Votre session a expiré. Veuillez vous reconnecter.';
        return;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de récupérer votre profil.',
      );
    } catch (e) {
      _errorMessage = _cleanException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // UPDATE PROFILE
  // ===========================================================================

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_isSaving) {
      return false;
    }

    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Le nom est obligatoire.';
      notifyListeners();
      return false;
    }

    if (cleanEmail.isEmpty) {
      _errorMessage = 'L’adresse email est obligatoire.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session utilisateur introuvable.');
      }

      final response = await http.put(
        Uri.parse(ApiConfig.currentUserAdmin),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': cleanName,
          'email': cleanEmail,
        }),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        final userData = _extractUser(body);

        if (userData != null) {
          _user = UserModel.fromJson(userData);
        } else {
          await loadprofile();
        }

        return true;
      }

      if (response.statusCode == 422) {
        _errorMessage = _extractError(
          body,
          fallback:
              'Les informations saisies sont invalides.',
        );
        return false;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de modifier le profil.',
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
  // CHANGE PASSWORD
  // ===========================================================================

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    if (_isSaving) {
      return false;
    }

    if (currentPassword.isEmpty) {
      _errorMessage =
          'Le mot de passe actuel est obligatoire.';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 8) {
      _errorMessage =
          'Le nouveau mot de passe doit contenir au moins 8 caractères.';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmation) {
      _errorMessage =
          'Les mots de passe ne correspondent pas.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session utilisateur introuvable.');
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.currentUserAdmin}/password',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        }),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        return true;
      }

      _errorMessage = _extractError(
        body,
        fallback:
            'Impossible de modifier le mot de passe.',
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

  Map<String, dynamic>? _extractUser(
    dynamic body,
  ) {
    if (body is! Map<String, dynamic>) {
      return null;
    }

    dynamic data = body['data'];

    if (data is Map<String, dynamic>) {
      data = data['user'] ?? data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (body['user'] is Map) {
      return Map<String, dynamic>.from(
        body['user'],
      );
    }

    // Certaines API retournent directement
    // les informations utilisateur.
    if (body.containsKey('id') ||
        body.containsKey('name') ||
        body.containsKey('email')) {
      return body;
    }

    return null;
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