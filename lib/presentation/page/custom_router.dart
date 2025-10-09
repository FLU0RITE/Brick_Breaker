import 'package:break_brick/presentation/page/start/start_page.dart';
import 'package:go_router/go_router.dart';

class CustomRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartPage()),
      GoRoute(path: '/login', builder: (context, state) => const StartPage()),
      GoRoute(path: '/multi', builder: (context, state) => const StartPage()),
      GoRoute(path: '/solo', builder: (context, state) => const StartPage()),
    ],
  );
}
