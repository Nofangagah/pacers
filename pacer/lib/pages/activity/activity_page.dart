import 'package:flutter/material.dart';
import 'package:pacer/service/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityPage extends StatefulWidget {
  final int userId;

  const ActivityPage({required this.userId, super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late Future<List<activityModel>> _activities;

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<List<activityModel>> _fetchActivities() async {
    final token = await _getAccessToken();
    if (token == null) throw Exception("Access token not found");
    return await ActivityService.getActivities(widget.userId);
  }

  @override
  void initState() {
    super.initState();
    _activities = _fetchActivities();
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String formatRelativeDate(String? dateString) {
    if (dateString == null) return "-";
    final date = DateTime.parse(dateString);
    return timeago.format(date, locale: 'id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Activities'), centerTitle: true),
      body: FutureBuilder<List<activityModel>>(
        future: _activities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('Failed to load activities')) {
              // Fallback for empty activity or server returning an error
              return const Center(
                child: Text('Belum ada aktivitas. Yuk mulai bergerak!'),
              );
            }
            return Center(child: Text('Terjadi kesalahan: $errorMessage'));
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return const Center(
              child: Text('Belum ada aktivitas. Yuk mulai bergerak!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    activity.type == 'run'
                        ? Icons.directions_run
                        : activity.type == 'walk'
                        ? Icons.directions_walk
                        : Icons.directions_bike,
                    size: 36,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    activity.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Date: ${formatRelativeDate(activity.date)}'),
                      Text(
                        'Distance: ${activity.distance?.toStringAsFixed(2)} km',
                      ),
                      Text(
                        'Duration: ${activity.duration != null ? formatDuration(activity.duration!) : "-"}',
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to detail
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
