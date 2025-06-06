import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;

class RunningPage extends StatefulWidget {
  const RunningPage({super.key});
  @override
  _RunningPageState createState() => _RunningPageState();
}

enum ActivityType { jalan, lari, sepeda }

class _RunningPageState extends State<RunningPage> {
  final Location _location = Location();
  LatLng? _currentPosition;
  LatLng? _startPosition;
  LatLng? _finishPosition;

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
  final List<LatLng> _routePoints = [];

  int steps = 0;
  int _startSteps = 0;
  bool _startStepsInitialized = false;

  Duration _elapsed = Duration.zero;

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

  late double _userWeightKg;
  final prefs = SharedPreferences.getInstance();

  bool _isSimulating = false;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _stepCountStream = Pedometer.stepCountStream.asBroadcastStream();
    _initializeLocation();
    _initializePedometer();
    _loadUserWeight();
  }
  Future<void> _loadUserWeight() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userWeightKg = prefs.getDouble('user_weight')!;
      
    });
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
    // Minta permission manual jika perlu
    if (await perm_handler.Permission.location.request().isDenied) {
      print("❌ Permission lokasi ditolak.");
      return;
    }

    if (await perm_handler.Permission.location.isPermanentlyDenied) {
      print("❌ Permission lokasi ditolak permanen. Minta buka settings.");
      perm_handler.openAppSettings();
      return;
    }

    if (await perm_handler.Permission.activityRecognition.request().isDenied) {
      print("❌ Permission activity recognition ditolak.");
      return;
    }

    // Cek dan minta akses lokasi dari plugin location
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print("❌ Layanan lokasi tidak diaktifkan.");
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("❌ Izin lokasi dari plugin Location ditolak.");
        return;
      }
    }

    // Lanjut dengan setup lokasi
    await _location.changeSettings(interval: 1000, distanceFilter: 0.1);

    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      final pos = LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentPosition = pos;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController.camera != null) {
          _mapController.move(pos, 16);
        }
      });
      print("📍 Lokasi awal: $_currentPosition");
    }

    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      if (_isSimulating) return;

      final newLat = locationData.latitude;
      final newLng = locationData.longitude;

      if (newLat == null || newLng == null) return;

      final newPosition = LatLng(newLat, newLng);
      final movedEnough =
          _currentPosition == null ||
          Distance().as(LengthUnit.Meter, _currentPosition!, newPosition) > 0.1;

      if (movedEnough) {
        print("📡 Lokasi berubah: $newPosition");
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
    });
  }

  void _startSimulation() {
    if (_currentPosition == null) return;

    const int stepsPerSecond = 3;
    const int tickSeconds = 2;
    final int stepsPerTick = stepsPerSecond * tickSeconds; // 6 langkah per tick
    final double stepLengthMeters =
        _getStepLength(); // kalibrasi panjang langkah

    _simulationTimer = Timer.periodic(Duration(seconds: tickSeconds), (_) {
      if (!_isRunning) return;

      _stopwatch.elapsed; // just to keep it running

      setState(() {
        steps += stepsPerTick;

        double distanceKm = (stepsPerTick * stepLengthMeters) / 1000;

        double deltaLat = distanceKm / 111.32;
        double deltaLng =
            distanceKm /
            (111.32 * cos(_currentPosition!.latitude * (pi / 180)));

        _currentPosition = LatLng(
          _currentPosition!.latitude + deltaLat,
          _currentPosition!.longitude + deltaLng,
        );

        _mapController.move(_currentPosition!, _mapController.camera.zoom);

        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;
          final distance = Distance().as(
            LengthUnit.Kilometer,
            lastPoint,
            _currentPosition!,
          );
          _totalDistance += distance;
        }

        _routePoints.add(_currentPosition!);

        // Perhitungan pace
        if (_stopwatch.elapsed.inSeconds > 0 && _totalDistance > 0) {
          final paceInSecondsPerKm =
              _stopwatch.elapsed.inSeconds / _totalDistance;
          avgPace = paceInSecondsPerKm / 60;
        } else {
          avgPace = 0;
        }

        // Perhitungan kalori
        final durationInHours = _stopwatch.elapsed.inSeconds / 3600;
        final met = _metRates[_selectedActivity] ?? 0.0;
        calories = (met * _userWeightKg * durationInHours).round();

        // Print untuk debugging
        print("Steps: $steps");
        print("Distance: ${_totalDistance.toStringAsFixed(3)} km");
        print("Avg Pace: ${avgPace.toStringAsFixed(2)} min/km");
        print("Calories: $calories");
      });
    });
  }

  double _getStepLength() {
    switch (_selectedActivity) {
      case ActivityType.lari:
        return 1.2; // meter per langkah untuk lari
      case ActivityType.sepeda:
        return 3.0; // meter per langkah untuk sepeda
      case ActivityType.jalan:
      default:
        return 0.7; // meter per langkah untuk jalan
    }
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
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
      _finishPosition = null;
    });

    if (_currentPosition != null) {
      _startPosition = _currentPosition;
      _routePoints.add(_currentPosition!);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) return;

      setState(() {
        final durationInSeconds = _stopwatch.elapsed.inSeconds;
        final durationInHours = durationInSeconds / 3600;

        // Hitung jarak alternatif dari langkah jika GPS kurang akurat
        final double stepLength = _getStepLength();
        final double stepDistanceKm = (steps * stepLength) / 1000;

        // Gunakan jarak GPS jika tersedia, atau jarak dari langkah
        final double effectiveDistance = max(_totalDistance, stepDistanceKm);

        // Perhitungan pace
        if (durationInSeconds > 0 && effectiveDistance > 0) {
          final paceInSecondsPerKm = durationInSeconds / effectiveDistance;
          avgPace = paceInSecondsPerKm / 60;
        } else {
          avgPace = 0;
        }

        // Perhitungan kalori
        final met = _metRates[_selectedActivity] ?? 0.0;
        calories = (met * _userWeightKg * durationInHours).round();

        print("Duration: ${_formatDuration(_stopwatch.elapsed)}");
        print("Effective Distance: ${effectiveDistance.toStringAsFixed(3)} km");
        print("Steps: $steps");
        print("Avg Pace: ${avgPace.toStringAsFixed(2)} min/km");
        print("Calories: $calories");
      });
    });

    if (_isSimulating) {
      _startSimulation();
    }

    // Inisialisasi langkah awal dengan error handling
    _stepCountStream.first
        .then((initial) {
          if (mounted && _isRunning) {
            setState(() {
              _startSteps = initial.steps;
              _startStepsInitialized = true;
            });
          }
        })
        .catchError((e) {
          print("Error getting initial steps: $e");
          // Fallback jika tidak bisa dapat langkah awal
          setState(() {
            _startSteps = 0;
            _startStepsInitialized = true;
          });
        });
  }

  void _stopRun() {
    _stopwatch.stop();
    _timer?.cancel();
    _stopSimulation();
    setState(() {
      _isRunning = false;
      _finishPosition = _currentPosition;
      _elapsed = _stopwatch.elapsed;
    });
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
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
                      color:
                          _currentPosition == null ? Colors.grey : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metric(
                        "Duration",
                        _formatDuration(
                          _isRunning ? _stopwatch.elapsed : _elapsed,
                        ),
                      ),
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
              child:
                  _currentPosition == null
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
                              if (_startPosition != null)
                                Marker(
                                  point: _startPosition!,
                                  width: 80,
                                  height: 80,
                                  child: Column(
                                    children: const [
                                      Icon(
                                        Icons.flag,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                                      Text(
                                        'Start',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_finishPosition != null)
                                Marker(
                                  point: _finishPosition!,
                                  width: 80,
                                  height: 80,
                                  child: Column(
                                    children: const [
                                      Icon(
                                        Icons.flag,
                                        color: Colors.blue,
                                        size: 30,
                                      ),
                                      Text(
                                        'Finish',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SwitchListTile(
                title: const Text("Aktifkan Simulasi"),
                value: _isSimulating,
                onChanged: (value) {
                  setState(() {
                    _isSimulating = value;
                  });
                  if (_isRunning) {
                    if (value) {
                      _startSimulation();
                    } else {
                      _stopSimulation();
                    }
                  }
                },
              ),
            ),
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
                            color:
                                isSelected
                                    ? Colors.black
                                    : Colors.grey.shade400,
                            width: 1.5,
                          ),
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
                onPressed:
                    _currentPosition == null
                        ? null
                        : (_isRunning ? _stopRun : _startRun),
                icon: Icon(
                  _isRunning ? Icons.stop : Icons.play_arrow,
                  color: Colors.black,
                ),
                label: Text(
                  _isRunning ? "STOP Running" : "START Running",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: _isRunning ? Colors.red : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
