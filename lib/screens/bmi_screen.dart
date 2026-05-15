import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';

class BMIScreen extends StatelessWidget {
  const BMIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final weightProv = context.watch<WeightProvider>();
    final latestWeight = weightProv.entries.isEmpty ? null : weightProv.entries.last.weightKg;

    final bmi = (user == null || user.heightCm == null || latestWeight == null)
        ? null
        : latestWeight / (user.heightM! * user.heightM!);

    return Scaffold(
      appBar: AppBar(title: const Text('BMI Insight')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF7C4DFF)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Body Mass Index', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    bmi == null ? 'Connect profile + weight' : bmi.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bmi == null ? 'Add your height and latest weight to see analysis.' : _bmiCategory(bmi),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: 'Recommendation',
              content: bmi == null
                  ? 'No profile data yet.'
                  : _recommendation(bmi, user?.goal),
            ),
            const SizedBox(height: 12),
            _InsightCard(
              title: 'How it helps',
              content: 'BMI gives a quick health signal. Combine it with steps, heart rate, and body weight trend for a fuller picture.',
            ),
          ],
        ),
      ),
    );
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static String _recommendation(double bmi, goal) {
    if (bmi < 18.5) return 'Focus on calorie-dense nutrition and strength training.';
    if (bmi < 25) return goal == null ? 'Maintain balanced diet and regular training.' : 'Keep a balanced plan and progressive overload.';
    if (bmi < 30) return 'Increase cardio frequency and control calories.';
    return 'Begin with low-impact cardio, mobility, and a structured nutrition plan.';
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;

  const _InsightCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF121826), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Color(0xFFAFB6C4), height: 1.5)),
        ],
      ),
    );
  }
}
