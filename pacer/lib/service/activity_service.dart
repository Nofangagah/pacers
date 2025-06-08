import 'dart:convert';
import 'package:pacer/helper/acces_token_helper.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:pacer/constant/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
      
      final requestBody = {
        'title': activity.title,
        'type': activity.type,
        'distance': activity.distance,
        'duration': activity.duration,
        'caloriesBurned': activity.caloriesBurned,
        'steps': activity.steps,
        'avr_pace': activity.avr_pace,
        'path': activity.path.map((p) => {
          'lat': p['lat']!,
          'lng': p['lng']!
        }).toList(),
        'date': activity.date,
        'userId': activity.userId,
        'createdAt': activity.createdAt,
        'updatedAt': activity.updatedAt,
      };

      print('Final request body: ${jsonEncode(requestBody)}');

      final response = await authorizedRequest(
        url,
        method: 'POST',
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return responseData.map((e) => ActivityModel.fromJson(e)).toList();
        }
        return [ActivityModel.fromJson(responseData)];
      } else if (response.statusCode == 401) {
        throw Exception('Session expired, please login again');
      } else {
        throw Exception('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Save error: $e');
      throw Exception('Failed to save activity: $e');
    }
  }

}
