import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/employees/attendance_history_model.dart';
import 'package:http/http.dart' as http;

class AttendanceService {
  final String token;

  AttendanceService({
    required this.token,
  });

  // ============================================================
  // HISTORIQUE D'UN EMPLOYÉ
  // ============================================================

  Future<List<AttendanceHistoryModel>> getEmployeeHistory(
    int employeeId,
  ) async {
    final url = ApiConfig.attendanceDetails(employeeId);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET $url');
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body);

      if (json['status'] != true) {
        throw Exception(
          json['message'] ?? 'Erreur lors de la récupération.',
        );
      }

      final data = json['data'];

      if (data == null) {
        return [];
      }

      final history = data['history'];

      if (history == null || history is! List) {
        return [];
      }

      return history
          .map(
            (item) => AttendanceHistoryModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('ERREUR getEmployeeHistory: $e');
      rethrow;
    }
  }
}