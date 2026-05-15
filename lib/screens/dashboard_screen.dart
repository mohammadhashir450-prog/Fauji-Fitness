import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/step_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final stepData = context.watch<StepProvider>();
    const neonGreen = Color(0xFFC7F000);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Custom Header (Greeting & Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ready to sweat,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user == null ? 'COMMANDO!' : user.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonGreen, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF151B12),
                      child: Icon(Icons.person, color: neonGreen, size: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 2. Main Activity Card (Steps Tracker)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826), // Dark Card Background
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'DAILY STEPS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Icon(Icons.directions_run, color: neonGreen),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Circular Progress & Steps Count
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 140,
                          width: 140,
                          child: CircularProgressIndicator(
                            // Real-time progress logic
                            value: stepData.progress > 1.0 ? 1.0 : stepData.progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.white10,
                            color: neonGreen,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${stepData.steps}', // Real Steps
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '/ ${stepData.dailyGoal}', // Real Goal
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Mini Stats Grid (Calories & Active Time)
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.local_fire_department,
                      title: 'CALORIES',
                      value: '${stepData.caloriesBurned}', // Real Calories
                      unit: 'kcal',
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.timer,
                      title: 'ACTIVE',
                      value: '${stepData.activeMinutes}', // Real Active Minutes
                      unit: 'mins',
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 4. Start Workout Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    shadowColor: neonGreen.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    // Yahan AI Camera screen ya Workout screen ka navigation aayega
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Workout Starting Soon!')),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 32),
                      SizedBox(width: 8),
                      Text(
                        'START WORKOUT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), // Bottom Navigation se overlap bachane k liye
            ],
          ),
        ),
      ),
    );
  }

  // Helper function for mini stats cards
  Widget _buildMiniStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

