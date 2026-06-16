import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/step_counter/presentation/step_counter_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/weight_tracker_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final isAuth = authState.value != null;
      final location = state.location;
      final isLogin = location == '/login';
      final isSplash = location == '/splash';

      if (!isAuth && !isLogin && !isSplash) return '/login';
      if (isAuth && isLogin) return '/dashboard';
      if (isAuth && isSplash) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', name: 'splash', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/dashboard', name: 'dashboard', builder: (context, state) => DashboardScreen()),
      GoRoute(path: '/steps', name: 'steps', builder: (context, state) => StepCounterScreen()),
      GoRoute(path: '/weight', name: 'weight', builder: (context, state) => WeightTrackerScreen()),
      GoRoute(path: '/profile', name: 'profile', builder: (context, state) => ProfileScreen()),
    ],
  );
});