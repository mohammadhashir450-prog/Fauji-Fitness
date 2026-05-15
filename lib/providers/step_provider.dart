import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepProvider extends ChangeNotifier {
  late Stream<StepCount> _stepCountStream;

  int _steps = 0;
  final int _dailyGoal = 10000;

  // Getters for UI
  int get steps => _steps;
  int get dailyGoal => _dailyGoal;
  double get progress => _dailyGoal == 0 ? 0.0 : _steps / _dailyGoal;
  int get caloriesBurned => (_steps * 0.04).toInt(); // 1 step = ~0.04 kcal
  int get activeMinutes => (_steps / 100).toInt();   // Rough estimate

  StepProvider() {
    initSensor();
  }

  Future<void> initSensor() async {
    // Pehle user se permission mangein
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      // Sensor ko listen karna shuru karein
      _stepCountStream = Pedometer.stepCountStream;
      StreamSubscription<StepCount> subscription = _stepCountStream.listen(onStepCount);
      subscription.onError(onStepCountError);
    } else {
      // For debugging; in production handle gracefully
      debugPrint("Permission denied for Activity Recognition");
    }
  }

  void onStepCount(StepCount event) {
    _steps = event.steps;
    notifyListeners(); // UI ko update karega
  }

  void onStepCountError(Object error) {
    debugPrint("Pedometer Error: $error");
  }
}
