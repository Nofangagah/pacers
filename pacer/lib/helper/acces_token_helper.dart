import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacer/service/auth_service.dart';

Future<http.Response> authorizedRequest(
  Uri url, {
  required String method,
  Map<String, String>? headers,
  dynamic body,
}) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('accessToken');

  headers ??= {};
  headers['Authorization'] = 'Bearer $accessToken';
  headers['Content-Type'] = 'application/json';

  http.Response response;

  try {
    response = await _sendRequest(url, method, headers, body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Token kadaluarsa → refresh
      bool refreshed = await AuthService.refreshAccessToken();
      if (!refreshed) return response;

      accessToken = prefs.getString('accessToken');
      headers['Authorization'] = 'Bearer $accessToken';

      // Coba ulangi request
      response = await _sendRequest(url, method, headers, body);
    }
  } catch (e) {
    rethrow;
  }

  return response;
}

Future<http.Response> _sendRequest(
  Uri url,
  String method,
  Map<String, String> headers,
  dynamic body,
) {
  switch (method.toUpperCase()) {
    case 'GET':
      return http.get(url, headers: headers);
    case 'POST':
      return http.post(url, headers: headers, body: body);
    case 'PUT':
      return http.put(url, headers: headers, body: jsonEncode(body));
    case 'DELETE':
      return http.delete(url, headers: headers);
    default:
      throw Exception('Unsupported HTTP method');
  }
}
