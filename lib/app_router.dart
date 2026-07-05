import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/base44_screen.dart'; // 👈 1. ADD THIS IMPORT

final appRouter = GoRouter(
  initialLocation: '/design',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/hunt', builder: (context, state) => const MapScreen()),
  ],
);