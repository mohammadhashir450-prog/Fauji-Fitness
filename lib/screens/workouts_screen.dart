import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final suggestions = _suggestions(user);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D0A),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFC7F000),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF0B0D0A),
                child: Icon(Icons.fitness_center, size: 12, color: Color(0xFFC7F000)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('FORGE AHEAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFFC7F000))),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF151B12), Color(0xFF0B0D0A)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFC7F000).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC7F000).withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7F000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI GUIDED PLANS',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Personalized Workouts',
                    style: TextStyle(color: Color(0xFFC7F000), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tailored workout suggestions based on your fitness profile and goals',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'RECOMMENDED FOR YOU',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
            const SizedBox(height: 12),
            ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF171816),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7F000).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFFC7F000), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['title'] as String,
                                style: const TextStyle(color: Color(0xFFC7F000), fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s['tag'] as String,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Color(0xFFC7F000), size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s['desc'] as String,
                      style: const TextStyle(color: Colors.white60, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, Object>> _suggestions(UserProfile? user) {
    final List<Map<String, Object>> out = [];
    final goal = user?.goal;

    if (goal == null) {
      out.add({
        'title': 'Get Started',
        'tag': 'SETUP REQUIRED',
        'desc': 'Set your profile and fitness goal to unlock personalized workout recommendations.',
      });
      return out;
    }

    if (goal == Goal.lose) {
      out.add({
        'title': 'Fat Loss Split',
        'tag': '4-6 DAYS/WEEK',
        'desc': 'High-intensity cardio combined with strength training to maximize fat burning and preserve muscle mass.',
      });
      out.add({
        'title': 'Morning Cardio',
        'tag': '30-40 MIN',
        'desc': 'Low-impact walking, running, or cycling to boost metabolism and build cardiovascular endurance.',
      });
      out.add({
        'title': 'HIIT Training',
        'tag': '15-20 MIN',
        'desc': 'Explosive intervals with recovery periods for maximum calorie burn in minimal time.',
      });
    } else if (goal == Goal.gain) {
      out.add({
        'title': 'Muscle Gain Split',
        'tag': '4-5 DAYS/WEEK',
        'desc': 'Push/Pull/Legs routine with progressive overload to build strength and muscle mass.',
      });
      out.add({
        'title': 'Heavy Compounds',
        'tag': '60-75 MIN',
        'desc': 'Squat, deadlift, bench press, and rows with focus on form and progressive weight increases.',
      });
      out.add({
        'title': 'Recovery Session',
        'tag': '20-30 MIN',
        'desc': 'Light mobility work, stretching, and breathing exercises to support muscle recovery.',
      });
    } else {
      out.add({
        'title': 'Balanced Weekly Plan',
        'tag': '4-5 DAYS/WEEK',
        'desc': '3 strength sessions and 2 cardio days to maintain fitness and overall wellness.',
      });
      out.add({
        'title': 'Mobility & Flexibility',
        'tag': '20-30 MIN',
        'desc': 'Dynamic stretching and foam rolling to improve range of motion and prevent injury.',
      });
      out.add({
        'title': 'Endurance Training',
        'tag': '45-60 MIN',
        'desc': 'Steady-state cardio to build aerobic capacity and improve cardiovascular health.',
      });
    }

    return out;
  }
}
