import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pacer/pages/activity/detail_activity_page.dart';
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
  late Future<List<ActivityModel>> _activities;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _activities = _fetchActivities();
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<List<ActivityModel>> _fetchActivities() async {
    final token = await _getAccessToken();
    if (token == null) throw Exception("Access token not found");
    return await ActivityService.getActivities(widget.userId);
  }

  Future<void> _refreshActivities() async {
    try {
      final newActivities = await _fetchActivities();
      if (mounted) {
        setState(() {
          _activities = Future.value(newActivities);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ulang: $e')),
        );
      }
    }
  }

  Future<void> _deleteActivity(int activityId) async {
    try {
      await ActivityService.deleteActivity(activityId);
      await _refreshActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitas berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus aktivitas: $e')),
        );
      }
      await _refreshActivities();
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _formatRelativeDate(ActivityModel activity) {
    try {
      final referenceDate = activity.createdAt ?? activity.date;
      if (referenceDate == null) return "Tanggal tidak tersedia";

      if (referenceDate is DateTime) {
        return timeago.format(referenceDate.toLocal(), locale: 'id');
      }

      if (referenceDate is String) {
        final cleanedDate = referenceDate.trim().replaceAll("'", "");
        
        try {
          return timeago.format(DateTime.parse(cleanedDate).toLocal(), locale: 'id');
        } catch (e) {
          try {
            final parsedDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleanedDate);
            return timeago.format(parsedDate.toLocal(), locale: 'id');
          } catch (e) {
            debugPrint("Gagal parsing tanggal: $cleanedDate");
            return "Format tanggal tidak valid";
          }
        }
      }

      return "Tipe tanggal tidak dikenali";
    } catch (e) {
      debugPrint("Error formatRelativeDate: $e");
      return "Error sistem";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Saya'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.white), // AppBar icons
      ),
      body: Container(
        color: Colors.black, // Dark background
        child: RefreshIndicator(
          onRefresh: _refreshActivities,
          child: FutureBuilder<List<ActivityModel>>(
            future: _activities,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Gagal memuat aktivitas',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: _refreshActivities,
                        child: const Text(
                          'Coba lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final activities = snapshot.data ?? [];

              if (activities.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada aktivitas',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Dismissible(
                    key: Key(activity.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.grey[800],
                            title: const Text(
                              "Konfirmasi",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "Apakah Anda yakin ingin menghapus aktivitas ini?",
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  "Batal",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text(
                                  "Hapus",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      await _deleteActivity(activity.id!);
                    },
                    child: Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailPage(activity: activity),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                activity.type == 'run'
                                    ? Icons.directions_run
                                    : activity.type == 'walk'
                                        ? Icons.directions_walk
                                        : Icons.directions_bike,
                                size: 36,
                                color: Colors.white, // White icon
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.title ?? 'Aktivitas Tanpa Judul',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatRelativeDate(activity),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          Icons.alt_route,
                                          '${activity.distance?.toStringAsFixed(0) ?? '0'} m',
                                        ),
                                        const SizedBox(width: 16),
                                        _buildDetailItem(
                                          Icons.timer,
                                          activity.duration != null 
                                              ? formatDuration(activity.duration!) 
                                              : '-',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white), // White icon
        const SizedBox(width: 4),
        Text(
          text, 
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}