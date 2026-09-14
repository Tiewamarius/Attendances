import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/dashboard_model.dart';
import 'package:http/http.dart' as http;

class DashboardService {
  DashboardService._();

  static Future<DashboardModel> getDashboard() async {
    final response = await http.get(
      Uri.parse(ApiConfig.dashboard),
      headers: await AuthService.headers(
        includeOrganization: true,
      ),
    );

    final Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Réponse serveur invalide.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ??
            'Impossible de récupérer le dashboard.',
      );
    }

    if (body['status'] != true) {
      throw Exception(
        body['message']?.toString() ??
            'Impossible de récupérer le dashboard.',
      );
    }

    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Les données du dashboard sont invalides.',
      );
    }

    return DashboardModel.fromJson(data);
  }
}