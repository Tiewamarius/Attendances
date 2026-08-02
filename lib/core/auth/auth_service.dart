import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static Future<bool> isLoggedIn() async {

    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    return token != null &&
        token.isNotEmpty;
  }


  static Future<String?> getToken() async {

    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');

  }


  static Future<void> logout() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');

  }

}