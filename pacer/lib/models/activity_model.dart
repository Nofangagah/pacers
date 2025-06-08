class ActivityModel {
  int? id;
  String title;
  String type;
  int duration;
  String date;
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
    return ActivityModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled Activity',
      type: json['type'] ?? 'walk',
      duration: json['duration'] ?? 0,
      date: json['date'] ?? DateTime.now().toIso8601String(),
      userId: json['userId'],
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      path: (json['path'] as List<dynamic>?)?.map((p) => {
        'lat': (p['lat'] as num).toDouble(),
        'lng': (p['lng'] as num).toDouble(),
      }).toList() ?? [],
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
      'date': date,
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