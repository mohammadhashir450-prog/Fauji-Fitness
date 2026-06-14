import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepProvider extends ChangeNotifier {
  final Health _health = Health();
  StreamSubscription<StepCount>? _pedometerSubscription;
  Timer? _refreshTimer;
  Timer? _syncTimer;

  int _steps = 0;
  int _heartRate = 0;
  int _dailyGoal = 10000;
  final int _dailyHeartGoal = 30;
  List<int> _weeklySteps = List.filled(7, 0);
  DateTime? _currentDay;
  int _lastSensorSteps = 0;
  DateTime? _lastEventTime;
  bool _initialized = false;

  int get steps => _steps;
  int get heartRate => _heartRate;
  int get dailyGoal => _dailyGoal;
  List<int> get weeklySteps => _weeklySteps;
  double get progress => _dailyGoal == 0 ? 0 : (_steps / _dailyGoal).clamp(0.0, 1.0);
  int get caloriesBurned => (_steps * 0.045).round();
  int get activeMinutes => (_steps / 100).floor();
  int get heartPoints => (_steps / 150).floor();
  double get heartPointsProgress => _dailyHeartGoal == 0 ? 0 : (heartPoints / _dailyHeartGoal).clamp(0.0, 1.0);

  StepProvider() {
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromPrefs();

    await [Permission.activityRecognition, Permission.sensors].request();
    await _configureHealth();
    await _loadTodaySnapshot();
    _startPedometerFallback();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => syncStepsWithSystem());
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _syncToFirestore());
  }

  Future<void> _configureHealth() async {
    try {
      await _health.configure();
    } catch (_) {
      // Keep app running even if Health Connect isn't available.
    }
  }

  Future<void> _loadTodaySnapshot() async {
    final now = DateTime.now();
    _ensureDay(now);
    await syncStepsWithSystem();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDateStr = prefs.getString('step_tracker_date');
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      if (savedDateStr == todayStr) {
        _steps = prefs.getInt('step_tracker_steps') ?? 0;
        _lastSensorSteps = prefs.getInt('step_tracker_last_sensor') ?? 0;
        _heartRate = prefs.getInt('step_tracker_heart_rate') ?? 0;
        final savedDay = prefs.getString('step_tracker_current_day');
        if (savedDay != null) {
          _currentDay = DateTime.parse(savedDay);
        }
      } else {
        _steps = 0;
        _lastSensorSteps = 0;
        _heartRate = 0;
        _currentDay = DateTime.now();
        await _saveToPrefs();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('step_tracker_date', todayStr);
      await prefs.setInt('step_tracker_steps', _steps);
      await prefs.setInt('step_tracker_last_sensor', _lastSensorSteps);
      await prefs.setInt('step_tracker_heart_rate', _heartRate);
      if (_currentDay != null) {
        await prefs.setString('step_tracker_current_day', _currentDay!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving to prefs: $e');
    }
  }

  void _ensureDay(DateTime now) {
    final current = DateTime(now.year, now.month, now.day);
    if (_currentDay == null || _currentDay != current) {
      _currentDay = current;
      _steps = 0;
      _lastSensorSteps = 0;
      _heartRate = 0;
      _weeklySteps = List.filled(7, 0);
      _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> syncStepsWithSystem() async {
    final now = DateTime.now();
    _ensureDay(now);

    final today = DateTime(now.year, now.month, now.day);
    int newSteps = _steps;
    int newHeartRate = _heartRate;

    try {
      final authorized = await _health.requestAuthorization([
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ]);
      if (authorized) {
        final stepsFromHealth = await _health.getTotalStepsInInterval(today, now);
        if (stepsFromHealth != null && stepsFromHealth > newSteps) {
          newSteps = stepsFromHealth;
        }

        final List<HealthDataPoint> heartRateData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: today,
          endTime: now,
        );

        if (heartRateData.isNotEmpty) {
          heartRateData.sort((a, b) => a.dateTo.compareTo(b.dateTo));
          final latestPoint = heartRateData.last;
          if (latestPoint.value is NumericHealthValue) {
            newHeartRate = (latestPoint.value as NumericHealthValue).numericValue.round();
          }
        }
      }
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }

    bool changed = false;
    if (newSteps > _steps) {
      _steps = newSteps.clamp(0, 1000000);
      changed = true;
    }
    if (newHeartRate != _heartRate) {
      _heartRate = newHeartRate;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      await _saveToPrefs();
      await _fetchWeeklyHistory();
      await _syncToFirestore();
    }
  }

  void _startPedometerFallback() {
    _pedometerSubscription?.cancel();
    _pedometerSubscription = Pedometer.stepCountStream.listen(
      (event) {
        _ensureDay(DateTime.now());
        final now = DateTime.now();
        final seconds = _lastEventTime == null ? 0.0 : now.difference(_lastEventTime!).inMilliseconds / 1000.0;
        
        if (_lastSensorSteps == 0) {
          _lastSensorSteps = event.steps;
          _lastEventTime = now;
        } else if (event.steps < _lastSensorSteps) {
          _lastSensorSteps = event.steps;
          _lastEventTime = now;
        } else {
          final diff = event.steps - _lastSensorSteps;
          if (diff > 0) {
            bool isJerk = false;
            if (seconds > 0.1) {
              final stepsPerSecond = diff / seconds;
              // Normal walking/running cannot physically exceed 4.0 steps per second.
              // Any rate higher than this is ignored as a device shake or bump.
              if (stepsPerSecond > 4.0) {
                isJerk = true;
                debugPrint('Pedometer Filter: Ignored $diff steps in $seconds seconds ($stepsPerSecond steps/sec) as false positive jerk.');
              }
            } else {
              if (diff > 1) {
                isJerk = true;
              }
            }

            if (!isJerk) {
              _steps += diff;
            }
            _lastSensorSteps = event.steps;
            _lastEventTime = now;
          }
        }
        
        notifyListeners();
        _saveToPrefs();
      },
      onError: (error) => debugPrint('Pedometer Error: $error'),
    );
  }

  Future<void> _fetchWeeklyHistory() async {
    final temp = <int>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final end = i == 0 ? now : start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      try {
        final steps = await _health.getTotalStepsInInterval(start, end);
        temp.add(steps ?? 0);
      } catch (_) {
        temp.add(0);
      }
    }
    _weeklySteps = temp;
    notifyListeners();
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _steps <= 0) return;

    final dateId = DateTime.now().toIso8601String().split('T')[0];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .doc(dateId)
        .set({
      'steps': _steps,
      'calories': caloriesBurned,
      'heartPoints': heartPoints,
      'heartRate': _heartRate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _syncTimer?.cancel();
    _pedometerSubscription?.cancel();
    super.dispose();
  }
}
