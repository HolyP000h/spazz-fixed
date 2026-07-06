import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login', // <-- Changed from '/design' to '/login'
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/hunt', builder: (context, state) => const MapScreen()),
  ],
);