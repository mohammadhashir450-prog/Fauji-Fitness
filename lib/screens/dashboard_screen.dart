import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../widgets/fitness_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final weightProv = context.watch<WeightProvider>();
    final latestWeight = weightProv.entries.isEmpty ? null : weightProv.entries.last.weightKg;
    final bmi = _bmiValue(user, latestWeight);
    final latestEntry = weightProv.entries.isNotEmpty ? weightProv.entries.last : null;
    final previousEntry = weightProv.entries.length > 1 ? weightProv.entries[weightProv.entries.length - 2] : null;
    final weightDelta = latestEntry != null && previousEntry != null ? latestEntry.weightKg - previousEntry.weightKg : null;
    final currentRem = latestWeight == null ? null : (2200 - (latestWeight * 10)).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D0A),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(radius: 14, backgroundColor: Color(0xFFC7F000), child: CircleAvatar(radius: 12, backgroundColor: Color(0xFF0B0D0A), child: Icon(Icons.fitness_center, size: 12, color: Color(0xFFC7F000)))),
            const SizedBox(width: 10),
            const Text('FAUJI FITNESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _FitnessDrawer(user: user, bmi: bmi),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            _HeroProgressCard(
              progress: latestWeight == null ? 0.0 : 0.82,
              calories: latestWeight == null ? null : (latestWeight * 10).round(),
              calorieGoal: latestWeight == null ? null : 2200,
              heartPoints: latestWeight == null ? null : (latestWeight / 2).round(),
              heartPointsGoal: latestWeight == null ? null : 60,
              activeMins: latestWeight == null ? null : (latestWeight * 1.5).round(),
              activeGoal: latestWeight == null ? null : 150,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetricCard(
                    title: 'WEIGHT',
                    value: latestWeight == null ? 'Not set' : latestWeight.toStringAsFixed(1),
                    suffix: latestWeight == null ? 'LOG WEIGHT' : 'LBS',
                    icon: Icons.monitor_weight_outlined,
                    accent: const Color(0xFFC7F000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetricCard(
                    title: 'DELTA',
                    value: weightDelta == null ? '—' : '${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)}',
                    suffix: weightDelta == null ? 'NO HISTORY' : 'LBS',
                    icon: Icons.trending_up,
                    accent: const Color(0xFFC7F000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniMetricCard(
                    title: 'BMI',
                    value: bmi == null ? 'Not set' : bmi.toStringAsFixed(1),
                    suffix: bmi == null ? 'ADD HEIGHT' : _bmiTag(bmi),
                    icon: Icons.favorite_border_rounded,
                    accent: const Color(0xFFC7F000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetricCard(
                    title: 'CALORIES',
                    value: currentRem == null ? 'Not set' : currentRem.toString(),
                    suffix: currentRem == null ? 'NO DATA' : 'REMAINING',
                    icon: Icons.local_fire_department_outlined,
                    accent: const Color(0xFFC7F000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const NeonSectionTitle(title: 'BODY METRICS'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _RealMetricCard(
                  icon: Icons.directions_walk_rounded,
                  title: 'STEPS',
                  value: null,
                  subtitle: 'Connect a tracker to view real steps',
                  accent: const Color(0xFFC7F000),
                ),
                _RealMetricCard(
                  icon: Icons.favorite_border_rounded,
                  title: 'HEART RATE',
                  value: null,
                  subtitle: 'Connect a wearable for live BPM',
                  accent: const Color(0xFFC7F000),
                ),
                _RealMetricCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'BMI',
                  value: bmi == null ? null : bmi.toStringAsFixed(1),
                  subtitle: bmi == null ? 'Add height and weight to calculate' : _bmiTag(bmi),
                  accent: const Color(0xFFC7F000),
                ),
                _RealMetricCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'WEIGHT LOGS',
                  value: '${weightProv.entries.length}',
                  subtitle: weightProv.entries.isEmpty ? 'No entries yet' : 'Stored in app',
                  accent: const Color(0xFFC7F000),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _WorkoutBanner(onStart: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout details coming soon!')));
            }),
            const SizedBox(height: 22),
            NeonSectionTitle(
              title: 'YOUR FAVORITES',
              actionLabel: 'VIEW ALL',
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved workouts coming soon!')));
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _FavoriteCard(title: 'Heavy Lifting', tag: '45 MIN', icon: Icons.fitness_center),
                  _FavoriteCard(title: 'Yoga Flow', tag: '30 MIN', icon: Icons.self_improvement),
                  _FavoriteCard(title: 'HIIT Burner', tag: '20 MIN', icon: Icons.bolt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double? _bmiValue(UserProfile? user, double? latestWeight) {
    if (user == null || user.heightCm == null || latestWeight == null) return null;
    final h = user.heightM!;
    return latestWeight / (h * h);
  }

  static String _bmiTag(double bmi) {
    if (bmi < 18.5) return 'HEALTHY';
    if (bmi < 25) return 'HEALTHY';
    if (bmi < 30) return 'ELEVATED';
    return 'HIGH';
  }
}

class _HeroProgressCard extends StatelessWidget {
  final double progress;
  final int? calories;
  final int? calorieGoal;
  final int? heartPoints;
  final int? heartPointsGoal;
  final int? activeMins;
  final int? activeGoal;

  const _HeroProgressCard({
    required this.progress,
    required this.calories,
    required this.calorieGoal,
    required this.heartPoints,
    required this.heartPointsGoal,
    required this.activeMins,
    required this.activeGoal,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = calories != null && calorieGoal != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151B12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(220, 220), painter: _RingPainter(hasData ? progress : 0.0)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(hasData ? '${(progress * 100).round()}%' : '--', style: const TextStyle(color: Color(0xFFC7F000), fontSize: 38, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('DAILY GOAL', style: TextStyle(color: Colors.white54, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProgressRow(label: 'CALORIES', value: hasData ? '$calories / $calorieGoal' : 'Not set', accent: const Color(0xFFC7F000)),
          const SizedBox(height: 10),
          _ProgressRow(label: 'HEART POINTS', value: heartPoints == null ? 'Not set' : '$heartPoints / $heartPointsGoal', accent: const Color(0xFFC7F000)),
          const SizedBox(height: 10),
          _ProgressRow(label: 'ACTIVE MINS', value: activeMins == null ? 'Not set' : '$activeMins / $activeGoal', accent: const Color(0xFFC7F000)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 12);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2C3316);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC7F000);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6A7C18);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(rect.deflate(18), -math.pi / 2, math.pi * 2 * 0.65, false, inner);
    canvas.drawArc(rect.deflate(36), -math.pi / 2, math.pi * 2 * progress, false, outer);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ProgressRow({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 2, height: 42, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RealMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final String subtitle;
  final Color accent;

  const _RealMetricCard({required this.icon, required this.title, required this.value, required this.subtitle, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151C12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700))),
            ],
          ),
          Text(value ?? 'Not set', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String suffix;
  final IconData icon;
  final Color accent;

  const _MiniMetricCard({required this.title, required this.value, required this.suffix, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF151B12), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, size: 15, color: accent), const SizedBox(width: 6), Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)))]),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WorkoutBanner extends StatelessWidget {
  final VoidCallback onStart;
  const _WorkoutBanner({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.84)]))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFC7F000), borderRadius: BorderRadius.circular(6)), child: const Text('WORKOUT OF THE DAY', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                const Text('ELITE CORE\nCRUSH', style: TextStyle(color: Colors.white, fontSize: 30, height: 0.95, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text('Master stability and explosive power with this high-intensity core protocol designed for elite athletes.', style: TextStyle(color: Colors.white70, height: 1.4)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 170,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC7F000), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: onStart,
                    child: const Text('START NOW'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String title;
  final String tag;
  final IconData icon;
  const _FavoriteCard({required this.title, required this.tag, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: const Color(0xFF151B12), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=800&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFC7F000), borderRadius: BorderRadius.circular(6)), child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)))),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(children: [Icon(icon, color: const Color(0xFFC7F000), size: 16), const Spacer(), const Icon(Icons.favorite_border, color: Colors.white70, size: 18)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FitnessDrawer extends StatelessWidget {
  final UserProfile? user;
  final double? bmi;
  const _FitnessDrawer({required this.user, required this.bmi});

  @override
  Widget build(BuildContext context) {
    final bmiText = bmi == null ? 'Set profile to unlock insights' : 'BMI ${bmi!.toStringAsFixed(1)}';
    return Drawer(
      backgroundColor: const Color(0xFF0B0D0A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF151B12), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 24, backgroundColor: Color(0xFFC7F000), child: Icon(Icons.person, color: Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user?.name ?? 'Guest', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(bmiText, style: const TextStyle(color: Colors.white54))])),
                  ],
                ),
              ),
            ),
            _drawerItem(context, Icons.home, 'Home', () {
              // set Home tab
              context.read<NavigationProvider>().setIndex(0);
              Navigator.pop(context);
            }),
            _drawerItem(context, Icons.monitor_weight, 'Weight Tracker', () {
              context.read<NavigationProvider>().setIndex(1);
              Navigator.pop(context);
            }),
            _drawerItem(context, Icons.groups, 'Community', () {
              context.read<NavigationProvider>().setIndex(2);
              Navigator.pop(context);
            }),
            _drawerItem(context, Icons.person, 'Profile', () {
              context.read<NavigationProvider>().setIndex(3);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: const Color(0xFFC7F000)), title: Text(title, style: const TextStyle(color: Colors.white)), onTap: onTap);
  }
}
