import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:pacer/service/notification_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:pacer/service/activity_service.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Constants for configuration
const double _locationUpdateIntervalMs = 1000; // milliseconds
const double _locationDistanceFilterMeters = 0.5; // meters
const double _initialMapZoom = 16.0;
const double _polylineStrokeWidth = 4.0;
const double _minDistanceForRouteUpdate = 1.0; // meters
const double _minSpeedThresholdMps = 0.3; // m/s (lower threshold for indoor)
const double _maxAcceptableAccuracy = 25.0; // meters (more lenient for indoor)
const int _minLocationUpdateIntervalSeconds = 2; // More frequent updates

// Constants for stationary detection (accelerometer)
const double _stationaryAccelerometerThreshold =
    0.15; // Lower threshold for indoor
const int _accelerometerWindowSize = 50; // Smaller window for faster response
const int _stationaryCheckDurationMs = 500; // Faster checks

// Constants for step length estimation
const double _averageStepLength = 0.75; // meters (average for walking/running)
const double _stepLengthVariation = 0.15; // meters (variation allowance)

class RunningPage extends StatefulWidget {
  const RunningPage({super.key});

  @override
  _RunningPageState createState() => _RunningPageState();
}

enum ActivityType { walk, run, ride }

class _RunningPageState extends State<RunningPage> {
  final Location _location = Location();
  LatLng? _currentPosition;
  LatLng? _startPosition;
  LatLng? _finishPosition;
  final TextEditingController _titleController = TextEditingController();

  late final MapController _mapController;
  bool _isRunning = false;
  bool _isPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  late Stream<StepCount> _stepCountStream;

  // Variables for stationary detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  List<AccelerometerEvent> _accelerometerReadings = [];
  bool _isStationary = true;
  Timer? _stationaryCheckTimer;

  // Variables for step-based distance estimation
  int _lastStepCount = 0;
  double _stepBasedDistance = 0.0;
  double _stepLength = _averageStepLength;

  int calories = 0;
  double avgPace = 0;
  double _totalDistance = 0.0;
  final List<LatLng> _routePoints = [];
  DateTime _lastPointTime = DateTime.now();

  int steps = 0;
  int _startSteps = 0;
  bool _startStepsInitialized = false;

  Duration _elapsed = Duration.zero;
  ActivityType _selectedActivity = ActivityType.run;

  // Tracking state
  bool _usingGps = true; // Start with GPS by default
  bool _gpsSignalLost = false;
  DateTime? _lastGoodGpsTime;

  final Map<ActivityType, Map<String, dynamic>> _activityInfo = {
    ActivityType.walk: {"label": "walk", "icon": Icons.directions_walk},
    ActivityType.run: {"label": "run", "icon": Icons.directions_run},
    ActivityType.ride: {"label": "ride", "icon": Icons.directions_bike},
  };

  final Map<ActivityType, double> _metRates = {
    ActivityType.walk: 3.8,
    ActivityType.run: 9.8,
    ActivityType.ride: 7.5,
  };

  late double _userWeightKg = 70.0;
  double _lastAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _stepCountStream = Pedometer.stepCountStream.asBroadcastStream();
    _initializeLocation();
    _initializePedometer();
    _initializeAccelerometer();
    _loadUserWeight();
     NotificationService.initLocalNotification();
  }

  Future<void> _loadUserWeight() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userWeightKg = prefs.getDouble('userWeight') ?? 70.0;
    });
  }

  Future<void> saveActivity() async {
    if (_routePoints.length < 2 || _totalDistance < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity too short to save.")),
      );
      _resetActivity();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Activity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Activity Title",
                hintText: "Example: Morning Run",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text("Total Distance: ${_totalDistance.toStringAsFixed(0)} m"),
            Text("Duration: ${_formatDuration(_stopwatch.elapsed)}"),
            Text("Steps: $steps"),
            Text("Calories: $calories cal"),
            Text("Tracking Mode: ${_usingGps ? 'GPS' : 'Step-based'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Title cannot be empty!")),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      _resetActivity();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');

      String activityType;
      switch (_selectedActivity) {
        case ActivityType.walk:
          activityType = "walk";
          break;
        case ActivityType.run:
          activityType = "run";
          break;
        case ActivityType.ride:
          activityType = "ride";
          break;
      }
      List<Map<String, double>> pathData = [];
      if (_usingGps && _routePoints.isNotEmpty) {
        pathData =
            _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
      } else if (!_usingGps) {
        pathData = [];
      }
      final activity = ActivityModel(
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : generateDefaultTitle(activityType, _totalDistance),
        type: activityType,
        distance: _totalDistance,
        duration: _stopwatch.elapsed.inSeconds,
        caloriesBurned: calories,
        steps: steps,
        avr_pace: avgPace,
        path: pathData,
        date: DateTime.now(),
        userId: userId,
      );

      final activityFinal = ActivityModel.fromJson(activity.toJson());
      validateActivity(activityFinal);
      await ActivityService.saveActivity(activityFinal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Activity saved successfully!")),
    );
    
    await NotificationService.showNotification(
      title: 'Activity Saved',
      body: '${activity.title} (${(_totalDistance/1000).toStringAsFixed(2)} km) was saved successfully',
    );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: ${e.toString()}")),
      );
    } finally {
      _resetActivity();
    }
  }

  void validateActivity(ActivityModel activity) {
    if (activity.title.isEmpty) throw Exception('Title cannot be empty!');
    if (activity.type.isEmpty) throw Exception('Activity type cannot be empty!');
  }

  String generateDefaultTitle(String activityType, double distance) {
    final activityNames = {'walk': 'walk', 'run': 'run', 'ride': 'ride'};
    return "${activityNames[activityType]} ${(_totalDistance / 1000).toStringAsFixed(0)} km";
  }

  void _resetActivity() {
    _titleController.clear();
    _stopwatch.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _totalDistance = 0.0;
      _stepBasedDistance = 0.0;
      steps = 0;
      calories = 0;
      avgPace = 0;
      _routePoints.clear();
      _startPosition = null;
      _finishPosition = null;
      _elapsed = Duration.zero;
      _lastPointTime = DateTime.now();
      _isStationary = true;
      _accelerometerReadings.clear();
      _usingGps = true;
      _gpsSignalLost = false;
      _lastGoodGpsTime = null;
    });
  }

  void _initializePedometer() {
    _stepCountSubscription = _stepCountStream.listen(
      (event) {
        if (!_isRunning || !_startStepsInitialized || _isPaused) return;

        final newSteps = event.steps - _startSteps;
        final stepDifference = newSteps - _lastStepCount;

        if (stepDifference > 0) {
          // Only update if steps increased
          setState(() {
            steps = newSteps;
            _lastStepCount = newSteps;

            // Update step-based distance
            if (!_usingGps) {
              _stepBasedDistance += stepDifference * _stepLength;
              _totalDistance = _stepBasedDistance;
              _updateMetrics();
            }
          });
        }
      },
      onError: (error) {
        print("Step Count Error: $error");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to get steps: $error")),
          );
        }
      },
      cancelOnError: true,
    );
  }

  void _initializeAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _accelerometerReadings.add(event);
      if (_accelerometerReadings.length > _accelerometerWindowSize) {
        _accelerometerReadings.removeAt(0);
      }
    });

    _stationaryCheckTimer = Timer.periodic(
      Duration(milliseconds: _stationaryCheckDurationMs),
      (_) {
        if (!mounted) return;
        _checkStationary();
      },
    );
  }

  void _checkStationary() {
    if (_accelerometerReadings.length < 5) {
      _isStationary = true;
      return;
    }

    double sumDelta = 0.0;
    for (int i = 1; i < _accelerometerReadings.length; i++) {
      final prev = _accelerometerReadings[i - 1];
      final curr = _accelerometerReadings[i];
      final deltaX = (curr.x - prev.x).abs();
      final deltaY = (curr.y - prev.y).abs();
      final deltaZ = (curr.z - prev.z).abs();
      sumDelta += (deltaX + deltaY + deltaZ);
    }

    final averageDelta = sumDelta / (_accelerometerReadings.length - 1);

    setState(() {
      _isStationary = averageDelta < _stationaryAccelerometerThreshold;
    });
    _accelerometerReadings.clear();
  }

  Future<void> _initializeLocation() async {
    if (await perm_handler.Permission.location.request().isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
      }
      return;
    }

    if (await perm_handler.Permission.location.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission permanently denied. Please enable in settings.",
            ),
          ),
        );
      }
      perm_handler.openAppSettings();
      return;
    }

    if (await perm_handler.Permission.activityRecognition.request().isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Activity recognition permission denied. Pedometer may not work.",
            ),
          ),
        );
      }
      return;
    }

    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location service not enabled.")),
          );
        }
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permission from plugin denied."),
            ),
          );
        }
        return;
      }
    }

    await _location.changeSettings(
      interval: _locationUpdateIntervalMs.toInt(),
      distanceFilter: _locationDistanceFilterMeters,
      accuracy: LocationAccuracy.high,
    );

    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      final pos = LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentPosition = pos;
        _lastAccuracy = locationData.accuracy ?? 0.0;
        _lastGoodGpsTime = DateTime.now();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController.camera != null) {
          _mapController.move(pos, _initialMapZoom);
        }
      });
    }

    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      if (_isPaused) return;
      
      final newLat = locationData.latitude;
      final newLng = locationData.longitude;
      _lastAccuracy = locationData.accuracy ?? 0.0;
      final currentSpeed = locationData.speed ?? 0.0;

      // Check if GPS signal is lost
      final now = DateTime.now();
      if (_lastAccuracy > _maxAcceptableAccuracy * 2 ||
          (newLat == null || newLng == null)) {
        if (!_gpsSignalLost) {
          setState(() {
            _gpsSignalLost = true;
          });
        }
      } else {
        if (_gpsSignalLost) {
          setState(() {
            _gpsSignalLost = false;
            _lastGoodGpsTime = now;
          });
        }
      }

      // Switch to step-based tracking if GPS is unreliable for too long
      if (_gpsSignalLost &&
          _lastGoodGpsTime != null &&
          now.difference(_lastGoodGpsTime!).inSeconds > 30) {
        if (_usingGps) {
          setState(() {
            _usingGps = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Switching to step-based tracking due to poor GPS signal",
              ),
            ),
          );
        }
        return;
      }

      if (newLat == null ||
          newLng == null ||
          _lastAccuracy > _maxAcceptableAccuracy) {
        return;
      }

      final newPosition = LatLng(newLat, newLng);

      // If we got a good GPS signal, switch back to GPS tracking
      if (!_usingGps && _lastAccuracy <= _maxAcceptableAccuracy) {
        setState(() {
          _usingGps = true;
          _lastGoodGpsTime = now;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "GPS signal restored, switching back to GPS tracking",
            ),
          ),
        );
      }

      final movedEnough = _currentPosition == null ||
          Distance().as(LengthUnit.Meter, _currentPosition!, newPosition) >=
              _minDistanceForRouteUpdate;

      final timeElapsedEnough =
          DateTime.now().difference(_lastPointTime).inSeconds >=
              _minLocationUpdateIntervalSeconds;

      final shouldAddPoint = _isRunning &&
          !_isPaused &&
          _usingGps &&
          movedEnough &&
          timeElapsedEnough &&
          (!_isStationary || (currentSpeed > _minSpeedThresholdMps));

      setState(() {
        if (shouldAddPoint) {
          if (_routePoints.isNotEmpty) {
            final lastPoint = _routePoints.last;
            final distance = Distance().as(
              LengthUnit.Meter,
              lastPoint,
              newPosition,
            );
            if (distance > _minDistanceForRouteUpdate) {
              _totalDistance += distance;
            }
          }
          _routePoints.add(newPosition);
          _updateMetrics();
          _lastPointTime = DateTime.now();
        }
        _currentPosition = newPosition;
        _mapController.move(newPosition, _mapController.camera.zoom);
      });
    });
  }

  void _updateMetrics() {
    final durationInSeconds = _stopwatch.elapsed.inSeconds;
    final durationInHours = durationInSeconds / 3600;

    if (_totalDistance > 0 && durationInHours > 0) {
      final met = _metRates[_selectedActivity] ?? 0.0;
      calories = (met * _userWeightKg * durationInHours).round();
    } else {
      calories = 0;
    }

    if (durationInSeconds > 0 && _totalDistance > 0) {
      final paceInSecondsPerKm = durationInSeconds / (_totalDistance / 1000);
      avgPace = paceInSecondsPerKm / 60;
    } else {
      avgPace = 0;
    }
  }

  void _startRun() {
    if (_currentPosition == null && !_gpsSignalLost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiting for GPS signal...")),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _stopwatch.reset();
      _stopwatch.start();
      _routePoints.clear();
      _totalDistance = 0.0;
      _stepBasedDistance = 0.0;
      avgPace = 0;
      calories = 0;
      steps = 0;
      _lastStepCount = 0;
      _startStepsInitialized = false;
      _finishPosition = null;
      _elapsed = Duration.zero;
      _lastPointTime = DateTime.now();
      _isStationary = true;
      _accelerometerReadings.clear();
    });

    if (_currentPosition != null) {
      _startPosition = _currentPosition;
      _routePoints.add(_currentPosition!);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning || _isPaused) return;
      setState(() {
        _updateMetrics();
      });
    });

    _stepCountStream.first
        .then((initial) {
          if (mounted && _isRunning && !_isPaused) {
            setState(() {
              _startSteps = initial.steps;
              _startStepsInitialized = true;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _startSteps = 0;
              _startStepsInitialized = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Pedometer unavailable or failed: $e")),
            );
          }
        });
  }

  void _pauseRun() {
    setState(() {
      _isPaused = true;
      _stopwatch.stop();
    });
  }

  void _resumeRun() {
    setState(() {
      _isPaused = false;
      _stopwatch.start();
    });
  }

  void _stopRun() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _finishPosition = _currentPosition;
      _elapsed = _stopwatch.elapsed;
    });
    saveActivity();
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  String _formatPace(double paceInMinutesPerKm) {
    if (paceInMinutesPerKm <= 0 || !paceInMinutesPerKm.isFinite)
      return "00:00 min/km";
    final minutes = paceInMinutesPerKm.floor();
    final seconds = ((paceInMinutesPerKm - minutes) * 60).round();
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min/km";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _stationaryCheckTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
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
                        ? "Acquiring location..."
                        : "GPS ${_usingGps ? 'Active' : 'Inactive'} (Accuracy: ${_lastAccuracy.toStringAsFixed(0)}m)",
                    style: TextStyle(
                      color: _currentPosition == null
                          ? Colors.grey
                          : (_lastAccuracy > _maxAcceptableAccuracy
                              ? Colors.orange
                              : Colors.green),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_gpsSignalLost && _usingGps)
                    const Text(
                      "Poor GPS signal - using step estimation",
                      style: TextStyle(color: Colors.orange),
                    ),
                  if (_isRunning && _isStationary && _totalDistance == 0)
                    const Text(
                      "Start moving to record route...",
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metric(
                        "Duration",
                        _formatDuration(
                            _isRunning ? _stopwatch.elapsed : _elapsed),
                      ),
                      _metric("Calories", "$calories cal"),
                      _metric("Avg. Pace", _formatPace(avgPace)),
                      _metric("Steps", "$steps"),
                      _metric(
                        "Distance",
                        "${_totalDistance.toStringAsFixed(0)} m",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _currentPosition == null && _usingGps
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition ?? const LatLng(0, 0),
                        initialZoom: _initialMapZoom,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: _usingGps ? Colors.blue : Colors.orange,
                                strokeWidth: _polylineStrokeWidth,
                              ),
                            ],
                          ),
                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 60,
                                height: 60,
                                child: Icon(
                                  Icons.location_pin,
                                  color: _usingGps ? Colors.red : Colors.orange,
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
                            _stepLength = type == ActivityType.run
                                ? _averageStepLength + _stepLengthVariation
                                : type == ActivityType.ride
                                    ? _averageStepLength * 2.5
                                    : _averageStepLength;
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
                            color: isSelected ? Colors.black : Colors.grey.shade400,
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_currentPosition == null && _usingGps)
                          ? null
                          : (_isRunning
                              ? (_isPaused ? _resumeRun : _pauseRun)
                              : _startRun),
                      icon: Icon(
                        _isRunning
                            ? (_isPaused ? Icons.play_arrow : Icons.pause)
                            : Icons.play_arrow,
                        color: Colors.black,
                      ),
                      label: Text(
                        _isRunning
                            ? (_isPaused ? "RESUME" : "PAUSE")
                            : "START ${_activityInfo[_selectedActivity]!['label'].toUpperCase()}",
                        style: const TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: _isRunning
                            ? (_isPaused ? Colors.green : Colors.orange)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isRunning)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopRun,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text(
                          "STOP",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}