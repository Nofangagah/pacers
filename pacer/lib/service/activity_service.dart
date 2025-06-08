import 'dart:convert';
import 'package:pacer/helper/acces_token_helper.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:pacer/constant/constant.dart';

class ActivityService {
  static Future<List<ActivityModel>> getActivities(int userId) async {
    final url = Uri.parse('${Constant.baseUrl}/activity/user/$userId');

    final response = await authorizedRequest(url, method: 'GET');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      print('Raw API response: ${response.body}');
      return jsonData.map((item) => ActivityModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load activities: ${response.body}');
    }
  } 

static Future<List<ActivityModel>> saveActivity(ActivityModel activity) async {
    try {
      final url = Uri.parse('${Constant.baseUrl}/activity/saveActivity');

      // Membangun request body
      final requestBody = {
        'title': activity.title,
        'type': activity.type,
        'distance': activity.distance,
        'duration': activity.duration,
        'caloriesBurned': activity.caloriesBurned,
        'steps': activity.steps,
        'avr_pace': activity.avr_pace,
        'path': activity.path.map((p) => {
          'lat': p['lat'],
          'lng': p['lng']
        }).toList(),
         'date': activity.date.toIso8601String(),
        'userId': activity.userId,
        'createdAt': activity.createdAt,
        'updatedAt': activity.updatedAt,
        // Hapus 'tracking_mode' dari requestBody
      };

      // Logging request body sebelum dikirim
      print('CLIENT: Final request body to server: ${jsonEncode(requestBody)}');

      final response = await authorizedRequest(
        url,
        method: 'POST',
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      // Logging respon lengkap dari server
      print('CLIENT: Server Response Status: ${response.statusCode}');
      print('CLIENT: Server Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) { // Menambahkan 200 sebagai kemungkinan sukses
        final responseData = jsonDecode(response.body); // Coba parse JSON
        print('CLIENT: Successfully parsed JSON response.');

        if (responseData is List) {
          return responseData.map((e) => ActivityModel.fromJson(e)).toList();
        } else if (responseData is Map<String, dynamic>) { // Menangani jika server mengembalikan single object
          return [ActivityModel.fromJson(responseData)];
        } else {
          print('CLIENT: Unexpected response format: ${responseData.runtimeType}');
          throw Exception('Unexpected response format from server');
        }
      } else if (response.statusCode == 401) {
        print('CLIENT: Authentication error: Session expired or unauthorized.');
        throw Exception('Session expired, please login again');
      } else if (response.statusCode == 400) {
          print('CLIENT: Bad Request error: ${response.body}');
          // Coba parse body untuk pesan error dari server
          try {
              final errorJson = jsonDecode(response.body);
              if (errorJson.containsKey('message')) {
                  throw Exception('Bad Request: ${errorJson['message']}');
              }
          } catch (e) {
              // Jika tidak bisa parse JSON, kembalikan body mentah
              throw Exception('Bad Request: ${response.body}');
          }
          throw Exception('Bad Request: ${response.body}'); // Fallback
      }
      else {
        // Logging error status code dan body
        print('CLIENT: Server returned error status code: ${response.statusCode}');
        print('CLIENT: Server error response body: ${response.body}');
        throw Exception('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Logging error pada sisi klien
      print('CLIENT: Save activity error: $e');
      throw Exception('Failed to save activity: $e');
    }
  }

}
