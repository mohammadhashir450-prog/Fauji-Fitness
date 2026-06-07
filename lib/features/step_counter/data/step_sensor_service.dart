import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart';

class StepSensorService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  final _controller = StreamController<int>.broadcast();
  int _todayOffset = 0; // To calculate daily steps from total boot steps

  Stream<int> get stepsStream => _controller.stream;

  void start() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  void _onStepCount(StepCount event) {
    // Note: Pedometer gives steps since boot.
    // In a real app, you'd subtract the value recorded at the start of the day.
    _controller.add(event.steps);
  }

  void _onStepCountError(error) {
    debugPrint("Pedometer Error: $error");
  }

  void stop() {
    _stepCountSubscription?.cancel();
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
