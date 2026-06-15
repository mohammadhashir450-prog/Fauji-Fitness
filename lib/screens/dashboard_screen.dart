import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../providers/user_provider.dart';
import '../providers/step_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  String? _currentLocality;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCurrentLocation();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isLocationLoading) return;
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocality = null;
          _isLocationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocality = null;
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocality = null;
          _isLocationLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? '';
        final stateName = placemark.administrativeArea ?? '';
        setState(() {
          if (city.isNotEmpty && stateName.isNotEmpty) {
            _currentLocality = "$city, $stateName";
          } else if (city.isNotEmpty) {
            _currentLocality = city;
          } else {
            _currentLocality = stateName;
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Widget _buildTextStat(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoalsCard(StepProvider stepData, Color neonGreen) {
    int achievedCount = 0;
    List<Widget> ringWidgets = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      int steps = stepData.weeklySteps[i];
      int heartPts = steps ~/ 150;

      if (steps >= stepData.dailyGoal) achievedCount++;

      double stepProg = steps / stepData.dailyGoal;
      double heartProg = heartPts / 30.0;

      DateTime d = now.subtract(Duration(days: 6 - i));
      String dayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
      final dateStr = "${d.day}/${d.month}/${d.year}";
      final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1];

      ringWidgets.add(
        Tooltip(
          message: '$dayName ($dateStr)\nSteps: $steps\nHeart Points: $heartPts',
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: false,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 30, width: 30,
                    child: CircularProgressIndicator(
                      value: stepProg > 1.0 ? 1.0 : stepProg,
                      strokeWidth: 3.5,
                      color: neonGreen,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(
                      value: heartProg > 1.0 ? 1.0 : heartProg,
                      strokeWidth: 3.5,
                      color: Colors.redAccent,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dayLetter,
                style: TextStyle(
                  color: i == 6 ? neonGreen : Colors.white54,
                  fontSize: 12,
                  fontWeight: i == 6 ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${d.day}',
                style: TextStyle(
                  color: i == 6 ? neonGreen.withValues(alpha: 0.8) : Colors.white30,
                  fontSize: 9,
                  fontWeight: i == 6 ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'YOUR DAILY GOALS',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 7 days',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$achievedCount/7',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: neonGreen,
                    ),
                  ),
                  const Text(
                    'Achieved',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ringWidgets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final stepData = context.watch<StepProvider>();
    const neonGreen = Color(0xFFC7F000);

    // Progress Calculations
    final double stepProgress = stepData.progress > 1.0 ? 1.0 : stepData.progress;
    final double heartProgress = stepData.heartPointsProgress > 1.0 ? 1.0 : stepData.heartPointsProgress;

    // Distance in km (1 step ≈ 0.000762 km)
    final String distanceKm = (stepData.steps * 0.000762).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
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
                      const SizedBox(height: 4),
                      if (_isLocationLoading)
                        const Row(
                          children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(neonGreen),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Locating...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        )
                      else if (_currentLocality != null && _currentLocality!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: neonGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _currentLocality!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: neonGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.location_off_outlined, color: Colors.white30, size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'Location not shared',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white30,
                              ),
                            ),
                          ],
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
              const SizedBox(height: 32),

              // 2. Activity Rings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(32),
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
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Heart Points Ring (Outer)
                          SizedBox(
                            height: 220,
                            width: 220,
                            child: CircularProgressIndicator(
                              value: heartProgress,
                              strokeWidth: 14,
                              backgroundColor: Colors.white10,
                              color: Colors.redAccent,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Steps Ring (Inner)
                          SizedBox(
                            height: 175,
                            width: 175,
                            child: CircularProgressIndicator(
                              value: stepProgress,
                              strokeWidth: 14,
                              backgroundColor: Colors.white10,
                              color: neonGreen,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${stepData.heartPoints}',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.redAccent,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                '${stepData.steps}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: neonGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    stepData.heartRate > 0 ? '${stepData.heartRate} BPM' : '-- BPM',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text('Heart Pts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 32),
                        const Icon(Icons.directions_run, color: neonGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text('Steps', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Container(height: 1, width: double.infinity, color: Colors.white10),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTextStat('${stepData.caloriesBurned}', 'Cal'),
                        _buildTextStat(distanceKm, 'km'),
                        _buildTextStat('${stepData.activeMinutes}', 'Move Min'),
                        _buildTextStat(stepData.heartRate > 0 ? '${stepData.heartRate}' : '--', 'BPM'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Weekly Goals Dual-Rings
              _buildWeeklyGoalsCard(stepData, neonGreen),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
