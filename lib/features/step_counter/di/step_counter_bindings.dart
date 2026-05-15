import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/step_repository_impl.dart';
import '../data/step_sensor_service.dart';
import '../domain/step_repository.dart';

final _serviceProvider = Provider((ref) => StepSensorService());
final _repoProvider = Provider<StepRepository>((ref) => StepRepositoryImpl(ref.read(_serviceProvider)));

void registerStepCounterProviders(ProviderContainer container) {
  // Wire up if manual container registration is needed
  // container.read(_serviceProvider);
}
