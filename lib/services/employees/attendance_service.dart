import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/attendance_history_model.dart';
import 'package:attendance/core/offline/connectivity_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      final response = await http
          .get(
            Uri.parse(url),
            headers: await AuthService.userHeaders(token: token),
          )
          .timeout(const Duration(seconds: 8));

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

      // Copie locale : consultable hors ligne.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(employeeId), jsonEncode(history));

      return _parseHistory(history);
    } catch (e) {
      print('ERREUR getEmployeeHistory: $e');

      // Hors ligne : on affiche la dernière copie connue.
      if (isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();

        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_cacheKey(employeeId));

        if (cached != null) {
          final decoded = jsonDecode(cached);

          if (decoded is List) return _parseHistory(decoded);
        }
      }

      rethrow;
    }
  }

  String _cacheKey(int employeeId) => 'cache_history_$employeeId';

  List<AttendanceHistoryModel> _parseHistory(List history) {
    return history
        .map(
          (item) => AttendanceHistoryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}