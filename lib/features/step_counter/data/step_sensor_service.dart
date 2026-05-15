import 'dart:async';

/// Platform-specific sensor integration would go here. This is a stubbed
/// service that simulates step events for the demo.
class StepSensorService {
  final _controller = StreamController<int>.broadcast();
  int _count = 0;
  Timer? _timer;

  Stream<int> get stepsStream => _controller.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _count += 12; // simulate steps
      _controller.add(_count);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
