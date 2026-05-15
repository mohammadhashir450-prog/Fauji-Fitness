import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'step_counter_controller.dart';

class StepCounterScreen extends ConsumerWidget {
  const StepCounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Step Counter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$steps', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(stepControllerProvider.notifier).start(),
              child: const Text('Start'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(stepControllerProvider.notifier).stop(),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
