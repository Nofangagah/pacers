import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pacer/pages/activity/detail_activity_page.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart'; // Import Provider
import 'package:pacer/pages/provider/activity_provider.dart'; // Import ActivityProvider

class ActivityPage extends StatefulWidget {
  final int userId;

  const ActivityPage({required this.userId, super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  // Hapus _activities Future dan _allActivities, karena data akan dikelola oleh ActivityProvider
  // late Future<List<ActivityModel>> _activities;
  // List<ActivityModel> _allActivities = [];

  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _searchController.addListener(_onSearchChanged);

    // --- PENTING: Panggil fetch data awal dari Provider di initState ---
    // Gunakan WidgetsBinding.instance.addPostFrameCallback
    // untuk memastikan context tersedia dan Provider sudah diinisialisasi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false).fetchActivities(widget.userId);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
    // Tidak perlu memanggil refresh data di sini.
    // Consumer akan otomatis merebuild UI saat state `_isSearching` berubah,
    // dan filter akan diterapkan pada data yang sudah ada di provider.
  }

  // Hapus _getAccessToken() karena sekarang ditangani di ActivityService/Provider
  // Hapus _fetchActivities() karena sekarang ditangani oleh ActivityProvider

  Future<void> _refreshActivities() async {
    // Panggil fungsi refreshActivities dari ActivityProvider
    await Provider.of<ActivityProvider>(context, listen: false).refreshActivities(widget.userId);
  }

  Future<void> _deleteActivity(int activityId) async {
    try {
      // Panggil fungsi delete di provider, yang juga akan memuat ulang data setelah sukses
      await Provider.of<ActivityProvider>(context, listen: false).deleteActivityAndUpdate(activityId, widget.userId);
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
      // Tidak perlu lagi memanggil _refreshActivities() di sini,
      // karena deleteActivityAndUpdate() di provider sudah melakukannya.
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
      // Asumsi activity.createdAt atau activity.date sudah berupa DateTime dari model
      // Jika masih string, pastikan parsing ada di model ActivityModel
      final dynamic referenceDate = activity.createdAt ?? activity.date;

      if (referenceDate == null) return "Tanggal tidak tersedia";
      if (referenceDate is DateTime) {
        return timeago.format(referenceDate.toLocal(), locale: 'id');
      }
      // Fallback jika masih string, tapi idealnya parsing harus di model
      if (referenceDate is String) {
        try {
          return timeago.format(DateTime.parse(referenceDate.trim().replaceAll("'", "")).toLocal(), locale: 'id');
        } catch (e) {
          debugPrint("Gagal parsing tanggal string: $referenceDate, Error: $e");
          return "Format tanggal tidak valid";
        }
      }
      return "Tipe tanggal tidak dikenali";
    } catch (e) {
      debugPrint("Error formatRelativeDate: $e");
      return "Error sistem";
    }
  }

  List<ActivityModel> _filterActivities(String query, List<ActivityModel> activities) {
    return activities.where((activity) {
      final title = activity.title?.toLowerCase() ?? '';
      final type = activity.type?.toLowerCase() ?? '';
      final date = _formatRelativeDate(activity).toLowerCase(); // Gunakan format relatif untuk pencarian
      final distance = activity.distance?.toString() ?? '';
      final duration = activity.duration?.toString() ?? '';

      return title.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase()) ||
          date.contains(query.toLowerCase()) ||
          distance.contains(query.toLowerCase()) ||
          duration.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search activities...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('My Activities'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: RefreshIndicator(
          onRefresh: _refreshActivities,
          // --- PENTING: Gunakan Consumer untuk mendengarkan perubahan dari ActivityProvider ---
          child: Consumer<ActivityProvider>(
            builder: (context, activityProvider, child) {
              if (activityProvider.isLoading && activityProvider.activities.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (activityProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Gagal memuat aktivitas: ${activityProvider.errorMessage}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
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

              List<ActivityModel> activitiesToShow = activityProvider.activities;
              // Apply search filter if searching
              if (_isSearching && _searchController.text.isNotEmpty) {
                activitiesToShow = _filterActivities(_searchController.text, activitiesToShow);
              }

              if (activitiesToShow.isEmpty) {
                return Center(
                  child: Text(
                    _isSearching && _searchController.text.isNotEmpty
                        ? 'Tidak ada aktivitas yang cocok ditemukan'
                        : 'Belum ada aktivitas yang direkam',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: activitiesToShow.length,
                itemBuilder: (context, index) {
                  final activity = activitiesToShow[index];
                  return Dismissible(
                    key: ValueKey(activity.id.toString()), // Menggunakan ValueKey untuk kinerja yang lebih baik
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
                      if (activity.id != null) {
                        await _deleteActivity(activity.id!); // Panggil fungsi delete yang baru
                      }
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
                                color: Colors.white,
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
        Icon(icon, size: 16, color: Colors.white),
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