class LatLng {
  final double lat;
  final double lng;

  LatLng({required this.lat, required this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}

class activityModel {
  int? id;
  String? title;
  String? type;
  int? duration;
  String? date;
  int? userId;
  double? distance;
  int? caloriesBurned;
  List<LatLng>? path; // Ubah dari String? ke List<LatLng>
  String? updatedAt;
  String? createdAt;

  activityModel({
    this.id,
    this.title,
    this.type,
    this.duration,
    this.date,
    this.userId,
    this.distance,
    this.caloriesBurned,
    this.path,
    this.updatedAt,
    this.createdAt,
  });

  factory activityModel.fromJson(Map<String, dynamic> json) {
    return activityModel(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      duration: json['duration'],
      date: json['date'],
      userId: json['userId'],
      distance: (json['distance'] as num?)?.toDouble(),
      caloriesBurned: json['caloriesBurned'],
      path: json['path'] != null
          ? (json['path'] as List)
              .map((e) => LatLng.fromJson(e))
              .toList()
          : null,
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
      'path': path?.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }
}
