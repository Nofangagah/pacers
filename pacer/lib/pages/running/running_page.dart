import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';

class RunningPage extends StatefulWidget {
  const RunningPage({super.key});
  @override
  _RunningPageState createState() => _RunningPageState();
}

enum ActivityType { jalan, lari, sepeda }

class _RunningPageState extends State<RunningPage> {
  final Location _location = Location();
  LatLng? _currentPosition;
  late final MapController _mapController;
  bool _isRunning = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  late Stream<StepCount> _stepCountStream;

  int calories = 0;
  double avgPace = 0;
  double _totalDistance = 0.0;
  List<LatLng> _routePoints = [];
  int steps = 0;
  int _startSteps = 0;
  bool _startStepsInitialized = false;

  ActivityType _selectedActivity = ActivityType.lari;

  final Map<ActivityType, Map<String, dynamic>> _activityInfo = {
    ActivityType.jalan: {"label": "Jalan", "icon": Icons.directions_walk},
    ActivityType.lari: {"label": "Lari", "icon": Icons.directions_run},
    ActivityType.sepeda: {"label": "Sepeda", "icon": Icons.directions_bike},
  };

  final Map<ActivityType, double> _metRates = {
    ActivityType.jalan: 3.8,
    ActivityType.lari: 9.8,
    ActivityType.sepeda: 7.5,
  };

  final double _userWeightKg = 60.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _stepCountStream = Pedometer.stepCountStream.asBroadcastStream();
    _initializeLocation();
    _initializePedometer();
  }

  void _initializePedometer() {
    _stepCountSubscription = _stepCountStream.listen(
      (event) {
        if (_isRunning && _startStepsInitialized) {
          setState(() {
            steps = event.steps - _startSteps;
          });
        }
      },
      onError: (error) => print("Step Count Error: $error"),
      cancelOnError: true,
    );
  }

  Future<void> _initializeLocation() async {
    bool _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    PermissionStatus _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
      _mapController.move(_currentPosition!, 16);
    }

    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final newPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        if (_currentPosition == null ||
            newPosition.latitude != _currentPosition!.latitude ||
            newPosition.longitude != _currentPosition!.longitude) {
          setState(() {
            _currentPosition = newPosition;
            _mapController.move(newPosition, _mapController.camera.zoom);

            if (_isRunning) {
              if (_routePoints.isNotEmpty) {
                final lastPoint = _routePoints.last;
                final distance = Distance().as(
                  LengthUnit.Kilometer,
                  lastPoint,
                  newPosition,
                );
                _totalDistance += distance;
              }
              _routePoints.add(newPosition);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  void _startRun() {
    setState(() {
      _isRunning = true;
      _stopwatch.reset();
      _stopwatch.start();
      _routePoints.clear();
      _totalDistance = 0.0;
      avgPace = 0;
      calories = 0;
      steps = 0;
      _startStepsInitialized = false;
    });

    if (_currentPosition != null) {
      _routePoints.add(_currentPosition!);
    }

    _stepCountStream.first.then((value) {
      setState(() {
        _startSteps = value.steps;
        _startStepsInitialized = true;
      });
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        final durationInSeconds = _stopwatch.elapsed.inSeconds;
        final durationInMinutes = durationInSeconds / 60;
        final durationInHours = durationInSeconds / 3600;

        final met = _metRates[_selectedActivity] ?? 0.0;
        calories = (met * _userWeightKg * durationInHours).round();

        if (_totalDistance > 0 && durationInMinutes > 0) {
          avgPace = durationInMinutes / _totalDistance;
        } else {
          avgPace = 0;
        }
      });
    });
  }

  void _stopRun() {
    setState(() {
      _isRunning = false;
      _stopwatch.stop();
      _timer?.cancel();
    });

    // Simpan hasil jika perlu
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    _currentPosition == null
                        ? "Mengambil lokasi..."
                        : "GPS Aktif",
                    style: TextStyle(
                      color: _currentPosition == null
                          ? Colors.grey
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metric("Duration", _formatDuration(_stopwatch.elapsed)),
                      _metric("Calories", "$calories cal"),
                      _metric(
                        "Avg. Pace",
                        avgPace > 0
                            ? "${avgPace.toStringAsFixed(2)} min/km"
                            : "00:00",
                      ),
                      _metric("Steps", "$steps"),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _currentPosition == null
                  ? Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue,
                                strokeWidth: 4.0,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: ActivityType.values.length,
                  itemBuilder: (context, index) {
                    final type = ActivityType.values[index];
                    final isSelected = type == _selectedActivity;

                    return GestureDetector(
                      onTap: () {
                        if (!_isRunning) {
                          setState(() {
                            _selectedActivity = type;
                          });
                        }
                      },
                      child: Container(
                        width: 65,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activityInfo[type]!['icon'],
                              size: 20,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activityInfo[type]!['label'],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: _currentPosition == null
                    ? null
                    : (_isRunning ? _stopRun : _startRun),
                icon: Icon(
                  _isRunning ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  _isRunning ? "STOP Running" : "START Running",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: _isRunning ? Colors.red : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
