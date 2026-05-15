import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/step_repository.dart';
import '../data/step_repository_impl.dart';
import '../data/step_sensor_service.dart';

final stepSensorServiceProvider = Provider((ref) => StepSensorService());
final stepRepoProvider = Provider<StepRepository>((ref) => StepRepositoryImpl(ref.read(stepSensorServiceProvider)));

final stepControllerProvider = StateNotifierProvider<StepController, int>((ref) {
  final repo = ref.watch(stepRepoProvider);
  return StepController(repo);
});

class StepController extends StateNotifier<int> {
  final StepRepository _repo;
  StreamSubscription<int>? _sub;

  StepController(this._repo) : super(0) {
    _sub = _repo.steps().listen((c) => state = c);
  }

  void start() => _repo.start();
  void stop() => _repo.stop();
  void disposeRepo() {
    _sub?.cancel();
    _repo.dispose();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
