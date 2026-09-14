import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/kiosk_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KioskService {
  const KioskService();

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    final organizationId =
        await AuthService.getOrganizationId();

    if (token == null || token.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    if (organizationId == null) {
      throw Exception('NO_ORGANIZATION');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Organization-Id':
          organizationId.toString(),
    };
  }

  Future<List<KioskModel>> getKiosks() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse(ApiConfig.kiosks),
      headers: headers,
    );

    debugPrint(
      '[KIOSKS] GET ${response.statusCode}',
    );

    debugPrint(
      '[KIOSKS] ${response.body}',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return _extractList(decoded)
          .whereType<Map>()
          .map(
            (item) => KioskModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de récupérer les kiosques.',
      ),
    );
  }

  Future<KioskModel> createKiosk({
    required String name,
    String? code,
    String? location,
    required String method,
    String? ipAddress,
    bool active = true,
  }) async {
    final headers = await _headers();

    final body = {
      'name': name.trim(),
      if (code != null && code.trim().isNotEmpty)
        'code': code.trim(),
      if (location != null &&
          location.trim().isNotEmpty)
        'location': location.trim(),
      'method': method,
      if (ipAddress != null &&
          ipAddress.trim().isNotEmpty)
        'ip_address': ipAddress.trim(),
      'active': active,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.kiosks),
      headers: headers,
      body: jsonEncode(body),
    );

    debugPrint(
      '[KIOSKS] POST ${response.statusCode}',
    );

    debugPrint(
      '[KIOSKS] ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      return KioskModel.fromJson(
        _extractObject(decoded),
      );
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de créer le kiosque.',
      ),
    );
  }

  Future<KioskModel> updateKiosk({
    required int id,
    required String name,
    String? code,
    String? location,
    required String method,
    String? ipAddress,
    bool? active,
  }) async {
    final headers = await _headers();

    final body = {
      'name': name.trim(),
      if (code != null) 'code': code.trim(),
      'location': location?.trim(),
      'method': method,
      'ip_address': ipAddress?.trim(),
      if (active != null) 'active': active,
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.kiosks}/$id'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return KioskModel.fromJson(
        _extractObject(decoded),
      );
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de modifier le kiosque.',
      ),
    );
  }

  Future<void> deleteKiosk(
    int id,
  ) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse('${ApiConfig.kiosks}/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        _extractError(
          response.body,
          'Impossible de supprimer le kiosque.',
        ),
      );
    }
  }

  Future<void> toggleKiosk(
    int id,
    bool active,
  ) async {
    final headers = await _headers();

    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.kiosks}/$id/toggle',
      ),
      headers: headers,
      body: jsonEncode({
        'active': active,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(
          response.body,
          'Impossible de modifier le statut du kiosque.',
        ),
      );
    }
  }

  List<dynamic> _extractList(
    dynamic decoded,
  ) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is! Map) {
      return [];
    }

    final data = decoded['data'];

    if (data is List) {
      return data;
    }

    if (data is Map) {
      if (data['data'] is List) {
        return data['data'];
      }

      if (data['kiosks'] is List) {
        return data['kiosks'];
      }
    }

    if (decoded['kiosks'] is List) {
      return decoded['kiosks'];
    }

    return [];
  }

  Map<String, dynamic> _extractObject(
    dynamic decoded,
  ) {
    if (decoded is Map) {
      final data = decoded['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      if (decoded['kiosk'] is Map) {
        return Map<String, dynamic>.from(
          decoded['kiosk'],
        );
      }

      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  String _extractError(
    String body,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }

        if (decoded['error'] != null) {
          return decoded['error'].toString();
        }

        final errors = decoded['errors'];

        if (errors is Map) {
          final messages = <String>[];

          errors.forEach((_, value) {
            if (value is List) {
              messages.addAll(
                value.map((e) => e.toString()),
              );
            } else if (value != null) {
              messages.add(value.toString());
            }
          });

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }
    } catch (_) {}

    return fallback;
  }
}