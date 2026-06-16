import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/step_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/weight_tracker_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/food_detector_screen.dart';
import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final health = Health();
      try {
        await health.configure();
      } catch (_) {}
      
      final hasPermissions = await health.hasPermissions([HealthDataType.STEPS]);
      if (hasPermissions == true) {
        final steps = await health.getTotalStepsInInterval(today, now);
        if (steps != null && steps > 0) {
          final prefs = await SharedPreferences.getInstance();
          final todayStr = now.toIso8601String().split('T')[0];
          
          final savedDateStr = prefs.getString('step_tracker_date');
          int currentSteps = 0;
          if (savedDateStr == todayStr) {
            currentSteps = prefs.getInt('step_tracker_steps') ?? 0;
          }
          
          if (steps > currentSteps) {
            await prefs.setString('step_tracker_date', todayStr);
            await prefs.setInt('step_tracker_steps', steps);
            
            final historyJson = prefs.getString('step_tracker_history');
            Map<String, dynamic> history = {};
            if (historyJson != null) {
              try {
                history = jsonDecode(historyJson) as Map<String, dynamic>;
              } catch (_) {}
            }
            history[todayStr] = steps;
            
            if (history.length > 10) {
              final sortedKeys = history.keys.toList()..sort();
              while (history.length > 10) {
                history.remove(sortedKeys.removeAt(0));
              }
            }
            await prefs.setString('step_tracker_history', jsonEncode(history));
            
            try {
              if (Firebase.apps.isEmpty) {
                await Firebase.initializeApp();
              }
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('activity')
                    .doc(todayStr)
                    .set({
                  'steps': steps,
                  'calories': (steps * 0.045).round(),
                  'heartPoints': (steps / 150).floor(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            } catch (fe) {
              debugPrint('Background Firebase Sync Error: $fe');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Background Workmanager Sync Error: $e');
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Seed the user's provided API key if no key is currently stored
    if (prefs.getString('gemini_api_key') == null) {
      await prefs.setString('gemini_api_key', 'AIzaSyBffxYEvQx99C3wo-FWUx4_-B3M-f_p7Uc');
    }
    if (prefs.getString('firebase_api_key') == null) {
      await prefs.setString('firebase_api_key', 'AIzaSyBffxYEvQx99C3wo-FWUx4_-B3M-f_p7Uc');
    }

    final customApiKey = prefs.getString('firebase_api_key') ?? prefs.getString('gemini_api_key');
    if (customApiKey != null && customApiKey.isNotEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: customApiKey,
          appId: "1:123456789012:android:abcdef1234567890",
          messagingSenderId: "123456789012",
          projectId: "mock-fauji-fitness",
          storageBucket: "mock-fauji-fitness.appspot.com",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Initialize Workmanager background sync
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      "step_sync_task",
      "syncStepsTask",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint("Workmanager initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final StorageService storage;

  const MyApp({super.key, StorageService? storage})
      : storage = storage ?? const StorageService();

  ThemeData _buildTheme({required bool dark, required Color neonGreen}) {
    final scaffoldBg = dark ? const Color(0xFF0B0D0A) : Colors.white;
    final cardBg = dark ? const Color(0xFF121826) : const Color(0xFFF4F6F8);
    final surfaceBg = dark ? const Color(0xFF111310) : const Color(0xFFFFFFFF);
    final foreground = dark ? Colors.white : Colors.black87;
    final secondary = dark ? const Color(0xFFD7DBE5) : const Color(0xFF4A5568);

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: neonGreen,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: cardBg,
        primary: neonGreen,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBg,
        foregroundColor: foreground,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceBg,
        indicatorColor: neonGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.black : secondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.black : secondary,
            size: 24,
          );
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: foreground),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: foreground),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: foreground),
        bodyLarge: TextStyle(fontSize: 16, color: secondary),
        bodyMedium: TextStyle(fontSize: 14, color: secondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonGreen = Color(0xFFC7F000);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => WeightProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => StepProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProv, _) {
          final darkMode = userProv.darkMode;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Fauji Fitness',
            theme: _buildTheme(dark: false, neonGreen: neonGreen),
            darkTheme: _buildTheme(dark: true, neonGreen: neonGreen),
            themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static dynamic of(BuildContext context) => context.findAncestorStateOfType<_AppShellState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void setIndex(int index) {
    context.read<NavigationProvider>().setIndex(index);
  }

  void openHamburgerMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void navigateFromDrawer(int index) {
    Navigator.of(context).pop();
    setIndex(index);
  }

  double? _bmiValue(UserProfile? user, double? latestWeight) {
    if (user == null || user.heightCm == null || latestWeight == null) return null;
    final h = user.heightM;
    if (h == null || h == 0) return null;
    final weightKg = latestWeight * 0.45359237; // convert lbs to kg for BMI
    return weightKg / (h * h);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final user = context.watch<UserProvider>().user;
    final weightProv = context.watch<WeightProvider>();

    final latestWeight = weightProv.entries.isEmpty ? null : weightProv.entries.last.weightKg;
    final bmi = _bmiValue(user, latestWeight);
    final index = nav.index;

    final pages = [
      const DashboardScreen(),
      const WeightTrackerScreen(),
      const FoodDetectorScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _GlobalFitnessDrawer(
        user: user,
        bmi: bmi,
        onNavigate: navigateFromDrawer,
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC7F000).withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => context.read<NavigationProvider>().setIndex(value),
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: const Color(0xFFC7F000),
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Weight'),
              NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Scan Food'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalFitnessDrawer extends StatelessWidget {
  final UserProfile? user;
  final double? bmi;
  final ValueChanged<int> onNavigate;

  const _GlobalFitnessDrawer({
    required this.user,
    required this.bmi,
    required this.onNavigate,
  });

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
                decoration: BoxDecoration(
                  color: const Color(0xFF151B12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFC7F000),
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(bmiText, style: const TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _drawerItem(Icons.home, 'Home', () => onNavigate(0)),
            _drawerItem(Icons.monitor_weight, 'Weight Tracker', () => onNavigate(1)),
            _drawerItem(Icons.fastfood, 'Food Scanner', () => onNavigate(2)),
            _drawerItem(Icons.person, 'Profile', () => onNavigate(3)),
            const Spacer(),
            _drawerItem(Icons.logout, 'Logout', () async {
              final authService = context.read<AuthService>();
              final userProvider = context.read<UserProvider>();
              await authService.signOut();
              await userProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC7F000)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
