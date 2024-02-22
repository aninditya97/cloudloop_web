import 'package:cloudloop_mobile/features/auth/presentation/presentation.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlarmPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/PumpPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  const AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router = GoRouter(
    routes: <GoRoute>[
      // Auth Module
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
        routes: [
          GoRoute(
            path: 'first-step',
            builder: (context, state) => const RegisterFirstStepPage(),
          ),
          GoRoute(
            path: 'second-step',
            builder: (context, state) => const RegisterSecondStepPage(),
          ),
          GoRoute(
            path: 'complete',
            builder: (context, state) => const RegisterCompletePage(),
          ),
        ],
      ),

      // Settings Module
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => PumpPage(),
      ),
      // GoRoute(
      //   path: '/scan/detail',
      //   builder: (context, state) {
      //     final name = state.extra! as BluetoothDevice;
      //     return DeviceScreen(
      //       device: name,
      //     );
      //   },
      // ),
      GoRoute(
        path: '/alarm',
        builder: (context, state) => AlarmPage(),
      ),

      // Report
      GoRoute(
        path: '/glucose-detail',
        builder: (context, state) => const BloodGlucoseDetail(),
        routes: [
          GoRoute(
            path: 'input',
            builder: (context, state) => const BloodGlucoseInputPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/report/insulin',
        builder: (context, state) => const ActiveInsulinDetail(),
      ),
      GoRoute(
        path: '/report/carbohydrate',
        builder: (context, state) => const ActiveCarbDetail(),
      ),
    ],
    errorBuilder: (context, state) {
      return Text('Error Page : ${state.error}');
    },
    // urlPathStrategy: UrlPathStrategy.path,
    debugLogDiagnostics: kDebugMode,
  );
}
