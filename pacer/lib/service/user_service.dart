import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacer/service/auth_service.dart';

class UserService {
  static const baseUrl = 'http://192.168.100.32:3000/api';

  static Future<bool> updateProfile(int userId, Map<String, dynamic> updates) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  if (token == null) return false;

  final url = Uri.parse('$baseUrl/user/editProfile/$userId');
  var response = await http.patch(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(updates),
  );

  if (response.statusCode == 403) {
    print('[updateProfile] Token kadaluarsa, coba refresh...');
    final success = await AuthService.refreshAccessToken();

    if (success) {
      token = prefs.getString('accessToken');
      response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );
    } else {
      print('[updateProfile] Gagal refresh token');
    }
  }

  print('[updateProfile] Status: ${response.statusCode}');
  print('[updateProfile] Body: ${response.body}');

  return response.statusCode == 200;
}

}
