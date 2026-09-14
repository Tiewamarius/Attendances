import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/employee_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmployeeService {
  EmployeeService._();

  // ==========================================================================
  // RESPONSE
  // ==========================================================================

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Erreur JSON EmployeeService: $e');
      debugPrint('Body: ${response.body}');
      return null;
    }
  }

  // ==========================================================================
  // EXTRACTION DATA
  // ==========================================================================

  static dynamic _extractData(dynamic body) {
    if (body is Map) {
      return body['data'] ?? body;
    }

    return body;
  }

  // ==========================================================================
  // MESSAGE ERREUR
  // ==========================================================================

  static String _errorMessage(
    http.Response response, {
    String fallback = 'Une erreur est survenue.',
  }) {
    final body = _decodeResponse(response);

    if (body is Map) {
      final message = body['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errors = body['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }

        if (firstError != null) {
          return firstError.toString();
        }
      }
    }

    return fallback;
  }

  // ==========================================================================
  // PROFIL EMPLOYÉ CONNECTÉ
  //
  // GET /employee/profile
  // ==========================================================================

  static Future<EmployeeModel?> getProfile() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('EmployeeService: aucun token utilisateur.');
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.employeeProfile),
        headers: await AuthService.headers(),
      );

      debugPrint(
        'Employee profile status: ${response.statusCode}',
      );

      debugPrint(
        'Employee profile response: ${response.body}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Employee profile error: ${_errorMessage(response)}',
        );

        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final data = _extractData(body);

      if (data is! Map) {
        debugPrint(
          'EmployeeService: format de réponse invalide.',
        );

        return null;
      }

      /*
       * Le backend peut retourner :
       *
       * {
       *   "status": true,
       *   "data": {
       *      "id": 1,
       *      ...
       *   }
       * }
       *
       * ou :
       *
       * {
       *   "status": true,
       *   "data": {
       *      "employee": {
       *         "id": 1,
       *         ...
       *      }
       *   }
       * }
       */

      final rawEmployee = data['employee'] ?? data;

      if (rawEmployee is! Map) {
        debugPrint(
          'EmployeeService: employee absent de la réponse.',
        );

        return null;
      }

      final employee = EmployeeModel.fromJson(
        Map<String, dynamic>.from(rawEmployee),
      );

      // Sauvegarde centralisée de l'employé
      await AuthService.saveEmployee(
        Map<String, dynamic>.from(rawEmployee),
      );

      return employee;
    } catch (e, stackTrace) {
      debugPrint(
        'Erreur EmployeeService.getProfile(): $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return null;
    }
  }

  // ==========================================================================
  // EMPLOYÉ SAUVEGARDÉ LOCALMENT
  // ==========================================================================

  static Future<EmployeeModel?> getSavedEmployee() async {
    try {
      final data = await AuthService.getSavedEmployee();

      if (data == null) {
        return null;
      }

      return EmployeeModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      debugPrint(
        'Erreur EmployeeService.getSavedEmployee(): $e',
      );

      return null;
    }
  }

  // ==========================================================================
  // RAFRAÎCHIR LE PROFIL
  // ==========================================================================

  static Future<EmployeeModel?> refreshProfile() async {
    return getProfile();
  }

  // ==========================================================================
  // SUPPRIMER LE PROFIL EMPLOYÉ LOCAL
  //
  // On ne déconnecte PAS l'utilisateur.
  // On supprime uniquement les données employee sauvegardées.
  // ==========================================================================

  static Future<void> clearSavedEmployee() async {
    try {
      await AuthService.saveEmployee(<String, dynamic>{});
    } catch (e) {
      debugPrint(
        'Erreur EmployeeService.clearSavedEmployee(): $e',
      );
    }
  }
}