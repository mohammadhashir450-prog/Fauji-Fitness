import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class StepProvider extends ChangeNotifier {
  int _steps = 0;
  final int _dailyGoal = 10000;
  bool _isLoading = false;

  // Getters for UI
  int get steps => _steps;
  int get dailyGoal => _dailyGoal;
  bool get isLoading => _isLoading;
  double get progress => _steps >= _dailyGoal ? 1.0 : _steps / _dailyGoal;
  int get caloriesBurned => (_steps * 0.04).toInt();
  int get activeMinutes => (_steps / 100).toInt();

  // Health API client
  final Health health = Health();

  StepProvider() {
    // App khulne par foran data fetch karega
    fetchDailySteps();
  }

  Future<void> fetchDailySteps() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Android Activity Recognition permission maangein
      final PermissionStatus permissionStatus = await Permission.activityRecognition.request();

      if (permissionStatus.isGranted) {
        // 2. Sirf Steps ka data define karein
        final List<HealthDataType> types = <HealthDataType>[HealthDataType.STEPS];

        // 3. Google Fit (Android) ya Apple Health (iOS) se authorize karwayein
        final bool requested = await health.requestAuthorization(types);

        if (requested) {
          // 4. Aaj raat 12:00 AM ka waqt nikaalein (Daily Reset logic)
          final DateTime now = DateTime.now();
          final DateTime startOfDay = DateTime(now.year, now.month, now.day);

          // 5. Interval ke darmiyan total steps uthaein
          final int? steps = await health.getTotalStepsInInterval(startOfDay, now);

          _steps = steps ?? 0;
          debugPrint('Steps Sync Successfully: $_steps');
        } else {
          debugPrint('Health Data Authorization Denied by User');
        }
      } else {
        debugPrint('Activity Recognition Permission Denied');
      }
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dashboard par pull-to-refresh k liye function
  Future<void> refreshSteps() async {
    await fetchDailySteps();
  }
}