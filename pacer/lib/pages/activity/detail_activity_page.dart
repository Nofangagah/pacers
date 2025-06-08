import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:pacer/models/activity_model.dart';

class ActivityDetailPage extends StatefulWidget {
  final ActivityModel activity;

  const ActivityDetailPage({required this.activity, super.key});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final MapController mapController = MapController();
  List<Polyline> polylines = [];
  List<Marker> markers = [];
  LatLngBounds? routeBounds;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    _prepareMapData();
  }

  void _prepareMapData() {
    if (widget.activity.path.isEmpty) return;

    final List<LatLng> points =
        widget.activity.path
            .map((p) => LatLng(p['lat'] ?? 0, p['lng'] ?? 0))
            .toList();

    final Distance distance = Distance();
    totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distance(points[i], points[i + 1]);
    }

    polylines.add(Polyline(points: points, color: Colors.blue, strokeWidth: 4));

    if (points.isNotEmpty) {
      markers.add(
        Marker(
          point: points.first,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );

      markers.add(
        Marker(
          point: points.last,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    if (points.length > 1) {
      final double minLat = points
          .map((p) => p.latitude)
          .reduce((a, b) => a < b ? a : b);
      final double maxLat = points
          .map((p) => p.latitude)
          .reduce((a, b) => a > b ? a : b);
      final double minLng = points
          .map((p) => p.longitude)
          .reduce((a, b) => a < b ? a : b);
      final double maxLng = points
          .map((p) => p.longitude)
          .reduce((a, b) => a > b ? a : b);

      routeBounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (routeBounds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cameraFit = CameraFit.bounds(
          bounds: routeBounds!,
          padding: const EdgeInsets.all(50),
        );
        mapController.fitCamera(cameraFit);
      });
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String getActivityTypeIcon(String type) {
    switch (type) {
      case 'run':
        return '🏃';
      case 'walk':
        return '🚶';
      case 'bike':
        return '🚴';
      default:
        return '🏅';
    }
  }

  String formatDistance(double meters) {
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(2)} km'
        : '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCameraPosition =
        widget.activity.path.isNotEmpty
            ? LatLng(
              widget.activity.path.first['lat'] ?? 0,
              widget.activity.path.first['lng'] ?? 0,
            )
            : const LatLng(0, 0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button with title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Activity Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Header with icon and title
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        getActivityTypeIcon(widget.activity.type),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.activity.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatDate(widget.activity.date),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Distance',
                            value: formatDistance(widget.activity.distance),
                            icon: Icons.flag,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Duration',
                            value: formatDuration(widget.activity.duration),
                            icon: Icons.timer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Pace',
                            value:
                                '${widget.activity.avr_pace.toStringAsFixed(2)} min/km',
                            icon: Icons.speed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Calories',
                            value: '${widget.activity.caloriesBurned} kcal',
                            icon: Icons.local_fire_department,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Steps',
                            value: '${widget.activity.steps}',
                            icon: Icons.directions_walk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Type',
                            value: widget.activity.type.toUpperCase(),
                            icon: Icons.category,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Map Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Route',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: initialCameraPosition,
                            initialZoom: 14,
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.pacer',
                            ),
                            PolylineLayer(polylines: polylines),
                            MarkerLayer(markers: markers),
                          ],
                        ),
                      ),
                    ),
                    if (widget.activity.path.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Calculated distance: ${formatDistance(totalDistance)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Additional Details Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Start Time',
                      formatDate(widget.activity.date),
                    ),
                    if (widget.activity.path.isNotEmpty)
                      _buildDetailRow(
                        context,
                        'Path Points',
                        '${widget.activity.path.length} coordinates',
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black, 
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => {Navigator.pop(context)},
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
