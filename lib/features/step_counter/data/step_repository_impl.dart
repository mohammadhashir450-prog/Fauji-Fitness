import '../domain/step_repository.dart';
import 'step_sensor_service.dart';

class StepRepositoryImpl implements StepRepository {
  final StepSensorService _service;
  StepRepositoryImpl(this._service);

  @override
  Stream<int> steps() => _service.stepsStream;

  @override
  void start() => _service.start();

  @override
  void stop() => _service.stop();

  @override
  void dispose() => _service.dispose();
}
