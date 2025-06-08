import 'dart:convert';
import 'package:intl/intl.dart'; 

class ActivityModel {
  int? id;
  String title;
  String type;
  int duration;
  DateTime date; 
  int? userId;
  double distance;
  int caloriesBurned;
  List<Map<String, double>> path;
  int steps;
  double avr_pace; 
  String? updatedAt;
  String? createdAt;

  ActivityModel({
    this.id,
    required this.title,
    required this.type,
    required this.duration,
    required this.date, 
    this.userId,
    required this.distance,
    required this.caloriesBurned,
    required this.path,
    required this.steps,
    required this.avr_pace,
    this.updatedAt,
    this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    print('ACTIVITY_MODEL: FromJson input: ${jsonEncode(json)}');

    List<Map<String, double>> parsedPath = [];

    if (json['path'] is String) {
      try {
        final List<dynamic> pathJson = jsonDecode(json['path']);
        parsedPath = pathJson.map((item) {
          if (item is Map<String, dynamic>) {
            return {
              'lat': (item['lat'] as num?)?.toDouble() ?? 0.0,
              'lng': (item['lng'] as num?)?.toDouble() ?? 0.0,
            };
          }
          return {'lat': 0.0, 'lng': 0.0};
        }).toList();
      } catch (e) {
        print('ACTIVITY_MODEL: Error parsing path string from JSON: $e');
      }
    } else if (json['path'] is List) {
      parsedPath = (json['path'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'lat': (item['lat'] as num?)?.toDouble() ?? 0.0,
                'lng': (item['lng'] as num?)?.toDouble() ?? 0.0,
              };
            }
            return {'lat': 0.0, 'lng': 0.0};
          })
          .toList();
    } else {
      print('ACTIVITY_MODEL: Path data is neither String nor List: ${json['path'].runtimeType}');
    }

    // Parsing date: Tangani format dari DB ('YYYY-MM-DD HH:MM:SS')
    DateTime parsedDate;
    final String? rawDateString = json['date'] as String?;
    if (rawDateString != null) {
      try {
        // Gunakan DateFormat untuk parsing yang spesifik
        // Asumsikan waktu di DB adalah waktu lokal server tanpa offset
        parsedDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(rawDateString);
      } catch (e) {
        print('ACTIVITY_MODEL: Error parsing date string "$rawDateString" from DB: $e');
        // Fallback jika parsing gagal: gunakan waktu sekarang (untuk debugging, ini bukan solusi permanen)
        parsedDate = DateTime.now(); 
      }
    } else {
      // Fallback jika json['date'] adalah null
      parsedDate = DateTime.now(); 
      print('ACTIVITY_MODEL: json["date"] is null. Using current DateTime as fallback.');
    }

    return ActivityModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled Activity',
      type: json['type'] ?? 'walk',
      duration: json['duration'] ?? 0,
      date: parsedDate, 
      userId: json['userId'],
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      path: parsedPath,
      steps: json['steps'] ?? 0,
      avr_pace: (json['avr_pace'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'duration': duration,
      'date': date.toIso8601String(), 
      'userId': userId,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'path': path.map((p) => {
        'lat': p['lat'],
        'lng': p['lng'],
      }).toList(),
      'steps': steps,
      'avr_pace': avr_pace,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }
}