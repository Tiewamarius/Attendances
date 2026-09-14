// import 'dart:convert';

// import 'package:attendance/core/auth/auth_service.dart';
// import 'package:attendance/core/network/api_endpoints.dart';
// import 'package:attendance/models/dashboard_model.dart';
// import 'package:http/http.dart' as http;

// class HomeService {
//   static final HomeService instance = HomeService._();

//   HomeService._();

//   factory HomeService() => instance;

//   // ============================================================
//   // DASHBOARD ADMIN
//   // ============================================================

//   Future<AdminDashboardModel> getDashboard() async {
//     final response = await http.get(
//       Uri.parse(ApiConfig.dashboard),
//       headers: await AuthService.headers(),
//     );

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception(_extractError(response));
//     }

//     final dynamic decoded = jsonDecode(response.body);

//     if (decoded is! Map<String, dynamic>) {
//       throw Exception('Réponse du serveur invalide.');
//     }

//     final dynamic payload =
//         decoded['data'] ?? decoded['dashboard'] ?? decoded;

//     if (payload is! Map<String, dynamic>) {
//       throw Exception('Données du tableau de bord invalides.');
//     }

//     return AdminDashboardModel.fromJson(payload);
//   }

//   // ============================================================
//   // PROFIL
//   // ============================================================

//   Future<Map<String, dynamic>> getProfile() async {
//     final response = await http.get(
//       Uri.parse(ApiConfig.profile),
//       headers: await AuthService.headers(),
//     );

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception(_extractError(response));
//     }

//     final dynamic decoded = jsonDecode(response.body);

//     if (decoded is! Map<String, dynamic>) {
//       throw Exception('Réponse du serveur invalide.');
//     }

//     final dynamic data = decoded['data'] ?? decoded['user'] ?? decoded;

//     if (data is! Map<String, dynamic>) {
//       throw Exception('Données du profil invalides.');
//     }

//     return Map<String, dynamic>.from(data);
//   }

//   // ============================================================
//   // CRÉER UN DÉPARTEMENT
//   // ============================================================

//   Future<Map<String, dynamic>> createDepartment({
//     required String name,
//     String? description,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConfig.departments),
//       headers: await AuthService.headers(
//         contentType: true,
//       ),
//       body: jsonEncode({
//         'name': name.trim(),
//         if (description != null && description.trim().isNotEmpty)
//           'description': description.trim(),
//       }),
//     );

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception(_extractError(response));
//     }

//     final dynamic decoded = jsonDecode(response.body);

//     if (decoded is! Map<String, dynamic>) {
//       throw Exception('Réponse du serveur invalide.');
//     }

//     final dynamic data = decoded['data'] ?? decoded['department'] ?? decoded;

//     if (data is! Map<String, dynamic>) {
//       throw Exception('Données du département invalides.');
//     }

//     return Map<String, dynamic>.from(data);
//   }

//   // ============================================================
//   // ERREUR API
//   // ============================================================

//   String _extractError(http.Response response) {
//     try {
//       final dynamic decoded = jsonDecode(response.body);

//       if (decoded is Map<String, dynamic>) {
//         final dynamic message = decoded['message'];

//         if (message != null && message.toString().trim().isNotEmpty) {
//           return message.toString();
//         }

//         final dynamic error = decoded['error'];

//         if (error != null && error.toString().trim().isNotEmpty) {
//           return error.toString();
//         }
//       }
//     } catch (_) {
//       // Réponse non JSON.
//     }

//     return 'Erreur serveur (${response.statusCode}).';
//   }
// }