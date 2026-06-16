import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';

import '../providers/user_provider.dart'; // Apna sahi path check kar lijiye ga
import '../main.dart'; // AppShell ko access karne ke liye
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final Future<void> delayFuture = Future.delayed(const Duration(seconds: 2));
    final Future<void> permissionFuture = _requestPermissions();

    // Wait for both the delay and permissions to resolve
    await Future.wait([delayFuture, permissionFuture]);

    _checkLoginStatus();
  }

  Future<void> _requestPermissions() async {
    try {
      // 1. Request Location, Activity Recognition, and Body Sensors permissions
      await [
        Permission.locationWhenInUse,
        Permission.activityRecognition,
        Permission.sensors,
      ].request();
    } catch (e) {
      debugPrint('General permissions request failed: $e');
    }

    try {
      // 2. Request Health Connect authorization
      final health = Health();
      await health.configure();
      await health.requestAuthorization([
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ]);
    } catch (e) {
      debugPrint('Health Connect authorization failed: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    // UserProvider se data read karein
    final userProvider = context.read<UserProvider>();

    // Agar user ka data pehle se save hai (yani wo logged in hai)
    if (userProvider.user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      // Agar data nahi hai to usay Login page par bhejein
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0A),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0D0A), Color(0xFF111310)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -60,
                child: _GlowBlob(color: const Color(0xFFC7F000).withValues(alpha: 0.12), size: 220),
              ),
              Positioned(
                bottom: -120,
                left: -80,
                child: _GlowBlob(color: const Color(0xFFC7F000).withValues(alpha: 0.08), size: 280),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121610),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC7F000), width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFC7F000).withValues(alpha: 0.18), blurRadius: 18, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFFC7F000), size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'FAUJI FITNESS',
                          style: TextStyle(
                            color: Color(0xFFC7F000),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC7F000).withValues(alpha: 0.22),
                                  const Color(0xFF111310),
                                ],
                              ),
                              border: Border.all(color: const Color(0xFFC7F000).withValues(alpha: 0.9), width: 4),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFC7F000).withValues(alpha: 0.12), blurRadius: 28, spreadRadius: 8),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 136,
                                  height: 136,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0B0D0A),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.fitness_center, color: Color(0xFFC7F000), size: 44),
                                    SizedBox(height: 8),
                                    Text(
                                      'FAUJI\nFITNESS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFC7F000),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        height: 0.9,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121610),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFC7F000).withValues(alpha: 0.18)),
                            ),
                            child: const Text(
                              'GET STRONG • STAY FIT',
                              style: TextStyle(
                                color: Color(0xFFC7F000),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121610),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC7F000),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [BoxShadow(color: const Color(0xFFC7F000).withValues(alpha: 0.45), blurRadius: 12)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Loading...',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}