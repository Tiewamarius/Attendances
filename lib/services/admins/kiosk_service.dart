import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/kiosk_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KioskService {
  KioskService._();

  // ============================================================
  // HEADERS ADMIN
  // ============================================================
  //
  // Toutes les opérations de ce service sont effectuées
  // avec le token de l'utilisateur administrateur.
  //
  // Le kiosk_token n'est PAS utilisé ici.
  // ============================================================

  static Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Session administrateur inexistante.',
      );
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // GET /kiosks
  // ============================================================
  //
  // Liste des kiosks appartenant à l'organisation courante.
  //
  // Token utilisé :
  //    token administrateur
  //
  // Laravel :
  //    GET /api/v1/kiosks
  // ============================================================

  static Future<List<KioskModel>> getKiosks() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.kiosks),
        headers: await _headers(),
      );

      debugPrint(
        'KioskService.getKiosks: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final body = jsonDecode(response.body);

      if (body is! Map) {
        throw Exception(
          'Réponse serveur invalide.',
        );
      }

      final data = body['data'] ?? body;

      // --------------------------------------------------------
      // Cas :
      // {
      //   "data": [
      //      {...},
      //      {...}
      //   ]
      // }
      // --------------------------------------------------------

      if (data is List) {
        return data
            .map(
              (item) => KioskModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      // --------------------------------------------------------
      // Cas :
      // {
      //   "data": {
      //      "kiosks": [...]
      //   }
      // }
      // --------------------------------------------------------

      if (data is Map && data['kiosks'] is List) {
        return (data['kiosks'] as List)
            .map(
              (item) => KioskModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      throw Exception(
        'Format de réponse des kiosks invalide.',
      );
    } catch (e) {
      debugPrint(
        'KioskService.getKiosks(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // GET /kiosks/{id}
  // ============================================================

  static Future<KioskModel> getKiosk(
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.kiosk(id)),
        headers: await _headers(),
      );

      debugPrint(
        'KioskService.getKiosk: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      return _parseKiosk(response);
    } catch (e) {
      debugPrint(
        'KioskService.getKiosk(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // POST /kiosks
  // ============================================================
  //
  // Création d'un kiosk par l'administrateur.
  // ============================================================

  static Future<KioskModel> createKiosk({
    required String name,
    String? location,
    required String method,
    String? ipAddress,
    required bool active,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.kiosks),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name.trim(),
          'location': location?.trim(),
          'method': method,
          'ip_address': ipAddress?.trim(),
          'active': active,
        }),
      );

      debugPrint(
        'KioskService.createKiosk: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _extractError(response),
        );
      }

      return _parseKiosk(response);
    } catch (e) {
      debugPrint(
        'KioskService.createKiosk(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // PUT /kiosks/{id}
  // ============================================================

  static Future<KioskModel> updateKiosk({
    required int id,
    required String name,
    String? location,
    required String method,
    String? ipAddress,
    required bool active,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.kiosk(id)),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name.trim(),
          'location': location?.trim(),
          'method': method,
          'ip_address': ipAddress?.trim(),
          'active': active,
        }),
      );

      debugPrint(
        'KioskService.updateKiosk: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      return _parseKiosk(response);
    } catch (e) {
      debugPrint(
        'KioskService.updateKiosk(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // PATCH /kiosks/{id}/toggle
  // ============================================================

  static Future<KioskModel> toggleKiosk(
    int id,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.kioskToggle(id)),
        headers: await _headers(),
      );

      debugPrint(
        'KioskService.toggleKiosk: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      return _parseKiosk(response);
    } catch (e) {
      debugPrint(
        'KioskService.toggleKiosk(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE /kiosks/{id}
  // ============================================================

  static Future<void> deleteKiosk(
    int id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.kiosk(id)),
        headers: await _headers(),
      );

      debugPrint(
        'KioskService.deleteKiosk: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(
          _extractError(response),
        );
      }
    } catch (e) {
      debugPrint(
        'KioskService.deleteKiosk(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // GET /kiosks/{id}/logs
  // ============================================================

  static Future<dynamic> getKioskLogs(
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.kioskLogs(id)),
        headers: await _headers(),
      );

      debugPrint(
        'KioskService.getKioskLogs: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final body = jsonDecode(response.body);

      if (body is Map) {
        return body['data'] ?? body;
      }

      return body;
    } catch (e) {
      debugPrint(
        'KioskService.getKioskLogs(): $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // PARSER KIOSK
  // ============================================================
  //
  // Accepte :
  //
  // {
  //   "data": {
  //      "kiosk": {...}
  //   }
  // }
  //
  // ou :
  //
  // {
  //   "data": {...}
  // }
  // ============================================================

  static KioskModel _parseKiosk(
    http.Response response,
  ) {
    final body = jsonDecode(response.body);

    if (body is! Map) {
      throw Exception(
        'Réponse serveur invalide.',
      );
    }

    final data = body['data'] ?? body;

    if (data is Map &&
        data['kiosk'] is Map) {
      return KioskModel.fromJson(
        Map<String, dynamic>.from(
          data['kiosk'],
        ),
      );
    }

    if (data is Map) {
      return KioskModel.fromJson(
        Map<String, dynamic>.from(
          data,
        ),
      );
    }

    throw Exception(
      'Format de réponse du kiosk invalide.',
    );
  }

  // ============================================================
  // EXTRACTION DES ERREURS
  // ============================================================

  static String _extractError(
    http.Response response,
  ) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map) {
        // ------------------------------------------------------
        // message
        // ------------------------------------------------------

        if (body['message'] != null) {
          final message =
              body['message'].toString().trim();

          if (message.isNotEmpty) {
            return message;
          }
        }

        // ------------------------------------------------------
        // error
        // ------------------------------------------------------

        if (body['error'] != null) {
          final error =
              body['error'].toString().trim();

          if (error.isNotEmpty) {
            return error;
          }
        }

        // ------------------------------------------------------
        // Laravel validation errors
        // ------------------------------------------------------

        if (body['errors'] is Map) {
          final errors =
              body['errors'] as Map;

          final messages = <String>[];

          for (final value in errors.values) {
            if (value is List) {
              messages.addAll(
                value.map(
                  (e) => e.toString(),
                ),
              );
            } else if (value != null) {
              messages.add(
                value.toString(),
              );
            }
          }

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }
    } catch (_) {
      // Le body n'est probablement pas du JSON.
    }

    return 'Erreur serveur (${response.statusCode}).';
  }
}