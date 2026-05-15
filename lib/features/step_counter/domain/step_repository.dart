abstract class StepRepository {
  Stream<int> steps();
  void start();
  void stop();
  void dispose();
}
