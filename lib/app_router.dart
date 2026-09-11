import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/life_coach_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/love_note_screen.dart';
import 'screens/bless_wisp_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login', // <-- Changed from '/design' to '/login'
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/social', builder: (context, state) => const HomeScreen(initialIndex: 1)),
    GoRoute(path: '/inventory', builder: (context, state) => const HomeScreen(initialIndex: 2)),
    GoRoute(path: '/profile', builder: (context, state) => const HomeScreen(initialIndex: 3)),
    GoRoute(path: '/hunt', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/feedback/:userId/:username',
      builder: (context, state) => FeedbackScreen(
        targetUserId: state.pathParameters['userId']!,
        targetUsername: state.pathParameters['username']!,
      ),
    ),
    GoRoute(path: '/coach', builder: (context, state) => const LifeCoachScreen()),
    GoRoute(
      path: '/chat/:friendId/:username',
      builder: (context, state) => ChatScreen(
        friendId: state.pathParameters['friendId']!,
        friendUsername: state.pathParameters['username']!,
      ),
    ),
    GoRoute(
      path: '/note/drop/:friendId/:username',
      builder: (context, state) => LoveNoteScreen(
        friendId: state.pathParameters['friendId']!,
        friendUsername: state.pathParameters['username']!,
      ),
    ),
    GoRoute(path: '/bless-wisp', builder: (context, state) => const BlessWispScreen()),
  ],
);
