import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pacer/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '130852023885-of55f25df0dg92o435fl90039mt773fk.apps.googleusercontent.com',
  );

  static const baseUrl = 'https://pacer-130852023885.us-central1.run.app/api/auth';

  /// Login dengan Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
       if (await _googleSignIn.isSignedIn()) {
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
  }
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'message': 'Login dibatalkan oleh pengguna'};
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Gagal mendapatkan ID Token'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login-google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        await saveUserData(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginMethod', 'google');

        return {'success': true, 'message': 'Login Google berhasil'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login Google gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi error: $e'};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final method = prefs.getString('loginMethod') ?? 'manual';
      final refreshToken = prefs.getString('refreshToken');

      if (refreshToken != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (method == 'google') {
        await _googleSignIn.signOut();
      }

      await prefs.clear();
      return {'success': true, 'message': 'Logout berhasil'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal logout: $e'};
    }
  }

  /// Register manual
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        await saveUserData(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginMethod', 'manual');

        return {'success': true, 'message': 'Registrasi berhasil'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi error: $e'};
    }
  }

  /// Login manual
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        await saveUserData(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginMethod', 'manual');
         await NotificationService().initNotification(data['user']['id']);
        return {
          'success': true,
          'message': 'Login berhasil',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi error: $e'};
    }
  }

  

  /// Simpan token
  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    if (kDebugMode) {
      print('[saveTokens] access: $accessToken');
      print('[saveTokens] refresh: $refreshToken');
    }
  }
static Future<bool> refreshAccessToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      print('[refreshAccessToken] Refresh token tidak ditemukan');
      return false;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'];
      if (accessToken == null) {
        print('[refreshAccessToken] accessToken tidak ada di response');
        return false;
      }

      await prefs.setString('accessToken', accessToken);
      print('[refreshAccessToken] Berhasil refresh accessToken');
      return true;
    } else {
      print('[refreshAccessToken] Gagal refresh: ${response.body}');
      return false;
    }
  } catch (e) {
    print('[refreshAccessToken] Error: $e');
    return false;
  }
}



  /// Simpan data user
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
     final weight = user['weight'];
  print('[saveUserData] Berat dari backend: $weight');
    await prefs.setInt('userId', user['id']);
    await prefs.setString('userName', user['name'] ?? '');
    await prefs.setString('userEmail', user['email'] ?? '');
    await prefs.setInt('userWeight', user['weight'] ?? 0);
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final loginMethod = prefs.getString('loginMethod');
    return accessToken != null && loginMethod != null;
  }
}
