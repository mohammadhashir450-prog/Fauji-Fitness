import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'providers/user_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/weight_tracker_screen.dart';
import 'screens/community_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final StorageService storage;
  const MyApp({super.key, StorageService? storage}) : storage = storage ?? const StorageService();

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
          return IconThemeData(color: selected ? Colors.black : secondary, size: 24);
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
    final neonGreen = const Color(0xFFC7F000);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => WeightProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void setIndex(int index) {
    context.read<NavigationProvider>().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final _index = nav.index;
    final _pages = const [
      DashboardScreen(),
      WeightTrackerScreen(),
      CommunityScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
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
            selectedIndex: _index,
            onDestinationSelected: (value) => context.read<NavigationProvider>().setIndex(value),
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: const Color(0xFFC7F000),
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Weight'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Community'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
