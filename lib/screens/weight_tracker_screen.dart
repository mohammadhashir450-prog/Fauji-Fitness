import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/weight_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/fitness_widgets.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _weight;
  int _selectedRange = 0;



  Widget _buildBmiCard(double? bmi, Color neonGreen) {
    if (bmi == null) return const SizedBox.shrink();
    final category = _bmiCategory(bmi);
    final isHealthy = category == 'HEALTHY';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: neonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.monitor_weight_outlined, color: neonGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BODY MASS INDEX (BMI)',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHealthy ? const Color(0xFFC7F000).withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isHealthy ? const Color(0xFFC7F000) : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WeightProvider>();
    final latest = prov.entries.isEmpty ? null : prov.entries.last.weightKg;
    final user = context.watch<UserProvider>().user;
    final bmi = _bmiFromWeight(latest, user);
    const neonGreen = Color(0xFFC7F000);

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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF121610),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('CURRENT WEIGHT', style: TextStyle(color: Colors.white60, letterSpacing: 1.2, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(
                    latest == null ? '--' : latest.toStringAsFixed(1),
                    style: const TextStyle(color: Color(0xFFC7F000), fontSize: 48, fontWeight: FontWeight.w900, height: 0.95),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('LBS', style: TextStyle(color: Color(0xFFC7F000), fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latest == null ? 'Last weigh-in: none' : 'Last weigh-in: ${_timeAgo(prov.entries.last.date)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC7F000),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (latest == null) {
                          if (_formKey.currentState != null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a weight in the log form below')));
                          }
                          return;
                        }
                        _showLogWeightSheet(context);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 22),
                          SizedBox(width: 10),
                          Text('LOG WEIGHT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weight History', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(
                  width: 170,
                  child: NeonPillToggle(
                    labels: const ['MONTH', 'WEEK', 'YEAR'],
                    selectedIndex: _selectedRange,
                    onChanged: (value) => setState(() => _selectedRange = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 270,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171816),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                children: [
                  CustomPaint(size: Size.infinite, painter: _ChartGridPainter()),
                  Positioned.fill(child: _WeightLineChart(entries: prov.entries)),
                  const Positioned(bottom: 0, left: 0, right: 0, child: _ChartAxisLabels()),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (bmi != null) ...[
              _buildBmiCard(bmi, neonGreen),
              const SizedBox(height: 18),
            ],
            const Text('Recent Logs', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (prov.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text('No weight entries yet', style: TextStyle(color: Colors.white54))),
              )
            else
              ...prov.entries.reversed.map((e) {
                final prev = _previousWeight(prov.entries, e);
                final diff = prev == null ? null : e.weightKg - prev;
                return NeonLogTile(
                  date: DateFormat('MMM dd, yyyy').format(e.date).toUpperCase(),
                  time: DateFormat('hh:mm a').format(e.date),
                  weight: '${e.weightKg.toStringAsFixed(1)} lbs',
                  delta: diff == null ? '--' : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} lbs',
                  deltaColor: diff == null
                      ? Colors.white38
                      : (diff <= 0 ? const Color(0xFFC7F000) : const Color(0xFFFF4D4D)),
                );
              }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showLogWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121610),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Log Weight', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Weight (lbs)'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _weight = v == null || v.isEmpty ? null : double.tryParse(v),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter weight' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();
                      final weightProvider = context.read<WeightProvider>();
                      final navigator = Navigator.of(context);
                      await weightProvider.addWeight(_weight!);
                      if (!mounted) return;
                      navigator.pop();
                      _formKey.currentState!.reset();
                    },
                    child: const Text('SAVE WEIGHT'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double? _bmiFromWeight(double? weight, UserProfile? user) {
    if (weight == null || user == null || user.heightCm == null) return null;
    final weightKg = weight * 0.45359237; // convert logged lbs to kg
    final h = user.heightCm! / 100.0;
    if (h == 0) return null;
    return weightKg / (h * h);
  }

  static double? _previousWeight(List entries, dynamic current) {
    final index = entries.indexOf(current);
    if (index <= 0) return null;
    return entries[index - 1].weightKg as double;
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'UNDERWEIGHT';
    if (bmi < 25) return 'HEALTHY';
    if (bmi < 30) return 'OVERWEIGHT';
    return 'OBESE';
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeightLineChart extends StatelessWidget {
  final List entries;
  const _WeightLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(entries),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List entries;
  _LinePainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final linePaint = Paint()
      ..color = const Color(0xFFC7F000)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shadowPaint = Paint()
      ..color = const Color(0xFFC7F000).withValues(alpha: 0.12)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final weights = entries.map((e) => (e.weightKg as num).toDouble()).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final span = (maxW - minW).abs() < 0.01 ? 1.0 : (maxW - minW);

    final points = <Offset>[];
    for (var i = 0; i < weights.length; i++) {
      final x = size.width * (i / (weights.length - 1));
      final normalized = (weights[i] - minW) / span;
      final y = size.height - (normalized * (size.height * 0.72)) - 18;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final c1 = Offset(prev.dx + (curr.dx - prev.dx) * 0.5, prev.dy);
      final c2 = Offset(curr.dx - (curr.dx - prev.dx) * 0.5, curr.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.entries != entries;
}

class _ChartAxisLabels extends StatelessWidget {
  const _ChartAxisLabels();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('OCT 01', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
          Text('OCT 15', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
          Text('OCT 31', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
