import 'dart:convert';
import 'package:pacer/helper/acces_token_helper.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:pacer/constant/constant.dart';

class ActivityService {
  static Future<List<activityModel>> getActivities(int userId) async {
    final url = Uri.parse('${Constant.baseUrl}/activity/user/$userId');

    final response = await authorizedRequest(url, method: 'GET');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      print('Raw API response: ${response.body}');
      return jsonData.map((item) => activityModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load activities: ${response.body}');
    }
  }
}
