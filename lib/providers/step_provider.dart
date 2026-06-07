import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepProvider extends ChangeNotifier {
  final Health _health = Health();
  StreamSubscription<StepCount>? _pedometerSubscription;
  Timer? _refreshTimer;
  Timer? _syncTimer;

  int _steps = 0;
  int _dailyGoal = 10000;
  final int _dailyHeartGoal = 30;
  List<int> _weeklySteps = List.filled(7, 0);
  DateTime? _currentDay;
  int _baselineSteps = 0;
  bool _initialized = false;

  int get steps => _steps;
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

  void _ensureDay(DateTime now) {
    final current = DateTime(now.year, now.month, now.day);
    if (_currentDay == null || _currentDay != current) {
      _currentDay = current;
      _baselineSteps = 0;
      _steps = 0;
      _weeklySteps = List.filled(7, 0);
      notifyListeners();
    }
  }

  Future<void> syncStepsWithSystem() async {
    final now = DateTime.now();
    _ensureDay(now);

    final today = DateTime(now.year, now.month, now.day);
    int newSteps = _steps;

    try {
      final authorized = await _health.requestAuthorization([HealthDataType.STEPS]);
      if (authorized) {
        final stepsFromHealth = await _health.getTotalStepsInInterval(today, now);
        if (stepsFromHealth != null) {
          newSteps = stepsFromHealth;
          _baselineSteps = stepsFromHealth;
        }
      } else {
        newSteps = _resolvePedometerFallback();
      }
    } catch (_) {
      newSteps = _resolvePedometerFallback();
    }

    if (newSteps != _steps) {
      _steps = newSteps.clamp(0, 1000000);
      notifyListeners();
      await _fetchWeeklyHistory();
    }
  }

  int _resolvePedometerFallback() {
    if (_baselineSteps > 0) {
      return _baselineSteps;
    }
    return _steps;
  }

  void _startPedometerFallback() {
    _pedometerSubscription?.cancel();
    _pedometerSubscription = Pedometer.stepCountStream.listen(
      (event) {
        _ensureDay(DateTime.now());
        if (_baselineSteps == 0) {
          _baselineSteps = event.steps;
        }
        final dailySteps = event.steps - _baselineSteps;
        final safeSteps = dailySteps < 0 ? 0 : dailySteps;
        if (safeSteps != _steps) {
          _steps = safeSteps;
          notifyListeners();
          _syncToFirestore();
        }
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
