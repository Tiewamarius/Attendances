import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/department_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DepartmentService {
  const DepartmentService();

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

  Future<List<DepartmentModel>> getDepartments() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse(ApiConfig.departments),
      headers: headers,
    );

    debugPrint(
      '[DEPARTMENTS] GET ${response.statusCode}',
    );

    debugPrint(
      '[DEPARTMENTS] ${response.body}',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return _extractList(decoded)
          .whereType<Map>()
          .map(
            (item) => DepartmentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de récupérer les départements.',
      ),
    );
  }

  Future<DepartmentModel> createDepartment({
    required String name,
    String? description,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse(ApiConfig.departments),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description':
            description?.trim().isEmpty == true
                ? null
                : description?.trim(),
      }),
    );

    debugPrint(
      '[DEPARTMENTS] POST ${response.statusCode}',
    );

    debugPrint(
      '[DEPARTMENTS] ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      final map = _extractObject(decoded);

      return DepartmentModel.fromJson(map);
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de créer le département.',
      ),
    );
  }

  Future<DepartmentModel> updateDepartment({
    required int id,
    required String name,
    String? description,
    bool? active,
  }) async {
    final headers = await _headers();

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.departments}/$id',
      ),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        if (active != null) 'active': active,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return DepartmentModel.fromJson(
        _extractObject(decoded),
      );
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de modifier le département.',
      ),
    );
  }

  Future<void> deleteDepartment(
    int id,
  ) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.departments}/$id',
      ),
      headers: headers,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        _extractError(
          response.body,
          'Impossible de supprimer le département.',
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

      if (data['departments'] is List) {
        return data['departments'];
      }
    }

    if (decoded['departments'] is List) {
      return decoded['departments'];
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

      if (decoded['department'] is Map) {
        return Map<String, dynamic>.from(
          decoded['department'],
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